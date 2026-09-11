import Foundation

/// Single-source-of-truth progress store. Every scene reads/writes through this
/// instance so persistence, summary statistics and child reports stay in sync.
@MainActor
final class ProgressStore {
    static let shared = ProgressStore()

    private(set) var completed: Set<String>
    private(set) var stars: [String: Int]
    private(set) var attempts: [String: Int]
    private(set) var lastPlayedLevelID: String?
    private(set) var lastPlayedAt: Date?
    private(set) var scenePractices: [ScenePractice]
    private(set) var familyPractice: Set<String>

    private let scenePracticesKey = "brightsprout.scenePractices.v1"
    private let familyPracticeKey = "brightsprout.familyPractice.v1"
    private let completedKey = "brightsprout.completed"
    private let starsKey = "brightsprout.stars"
    private let attemptsKey = "brightsprout.attempts"
    private let lastPlayedKey = "brightsprout.lastPlayedLevel"
    private let lastPlayedAtKey = "brightsprout.lastPlayedAt"
    private let defaults: UserDefaults
    private var didBootstrap = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        completed = []
        stars = [:]
        attempts = [:]
        scenePractices = []
        familyPractice = []
    }

    func bootstrap() {
        guard !didBootstrap else { return }
        didBootstrap = true
        scenePractices = defaults.data(forKey: scenePracticesKey)
            .flatMap { try? JSONDecoder().decode([ScenePractice].self, from: $0) } ?? []
        familyPractice = Set(defaults.stringArray(forKey: familyPracticeKey) ?? [])
        completed = Set(defaults.stringArray(forKey: completedKey) ?? [])
        stars = defaults.dictionary(forKey: starsKey) as? [String: Int] ?? [:]
        attempts = defaults.dictionary(forKey: attemptsKey) as? [String: Int] ?? [:]
        lastPlayedLevelID = defaults.string(forKey: lastPlayedKey)
        lastPlayedAt = defaults.object(forKey: lastPlayedAtKey) as? Date
        NotificationCenter.default.post(name: .progressStoreDidChange, object: nil)
    }

    func savePractice(_ practice: ScenePractice) {
        guard practice.completedCount > 0 || practice.steps.contains(where: {
            $0.incorrectAttempts + $0.replays + $0.hints > 0
        }) else { return }
        if let index = scenePractices.firstIndex(where: { $0.id == practice.id }) {
            scenePractices[index] = practice
        } else {
            scenePractices.append(practice)
        }
        scenePractices = Array(scenePractices.suffix(200))
        if let data = try? JSONEncoder().encode(scenePractices) {
            defaults.set(data, forKey: scenePracticesKey)
        }
        NotificationCenter.default.post(name: .progressStoreDidChange, object: nil)
    }

    func setFamilyPractice(_ levelID: String, completed: Bool) {
        if completed { familyPractice.insert(levelID) } else { familyPractice.remove(levelID) }
        defaults.set(Array(familyPractice), forKey: familyPracticeKey)
        NotificationCenter.default.post(name: .progressStoreDidChange, object: nil)
    }

    var suggestedReview: LevelDefinition? {
        var seen = Set<String>()
        for practice in scenePractices.reversed() where practice.finishedAt != nil {
            guard seen.insert(practice.levelID).inserted else { continue }
            if practice.needsPractice,
               let level = Curriculum.levels.first(where: { $0.id == practice.levelID }) { return level }
        }
        return nil
    }

    func complete(_ level: LevelDefinition, stars earned: Int = 3) {
        completed.insert(level.id)
        stars[level.id] = max(stars[level.id] ?? 0, min(3, max(1, earned)))
        attempts[level.id, default: 0] += 1
        lastPlayedLevelID = level.id
        lastPlayedAt = Date()
        defaults.set(Array(completed), forKey: completedKey)
        defaults.set(stars, forKey: starsKey)
        defaults.set(attempts, forKey: attemptsKey)
        defaults.set(level.id, forKey: lastPlayedKey)
        defaults.set(lastPlayedAt, forKey: lastPlayedAtKey)
        NotificationCenter.default.post(name: .progressStoreDidChange, object: nil)
    }

    func isUnlocked(_ level: LevelDefinition, in orderedLevels: [LevelDefinition]) -> Bool {
        guard let index = orderedLevels.firstIndex(of: level), index > 0 else { return true }
        return completed.contains(orderedLevels[index - 1].id)
    }

    /// Wipes all persisted state and re-bootstraps an empty store.
    /// Used by the parent dashboard "Reset Progress" action. Also clears
    /// the onboarding flag, so the next launch will run Welcome + Parent
    /// Primer again (S1-03).
    func resetAllProgress() {
        for key in defaults.dictionaryRepresentation().keys
        where key.hasPrefix("brightsprout.") {
            defaults.removeObject(forKey: key)
        }
        completed = []
        stars = [:]
        attempts = [:]
        scenePractices = []
        familyPractice = []
        lastPlayedLevelID = nil
        lastPlayedAt = nil
        didBootstrap = false
        bootstrap()
    }

    /// True once the child has completed at least one level. Drives the
    /// first-run routing decision in S1-01 (welcome scene) vs the main
    /// menu. Pillar 3 (Persistence): never lossy — we only flip this to
    /// `true`, never back, except via `resetAllProgress()`.
    var onboardingComplete: Bool { !completed.isEmpty }

    var totalStars: Int { stars.values.reduce(0, +) }
    var totalAttempts: Int { attempts.values.reduce(0, +) }

    /// Fractional completion for a single area (0.0 … 1.0). Useful
    /// for progress rings on the menu and parent dashboard.
    func completionRatio(for area: LearningArea) -> Double {
        let levels = Curriculum.levels(in: area)
        guard !levels.isEmpty else { return 0 }
        let done = levels.reduce(0) { acc, lvl in
            acc + (completed.contains(lvl.id) ? 1 : 0)
        }
        return Double(done) / Double(levels.count)
    }

    var recommendedLevel: LevelDefinition {
        if let lastPlayedLevelID,
           let last = Curriculum.levels.first(where: { $0.id == lastPlayedLevelID }) {
            let areaLevels = Curriculum.levels(in: last.area)
            if let index = areaLevels.firstIndex(of: last) {
                let remaining = areaLevels.dropFirst(index + 1)
                if let next = remaining.first(where: { !completed.contains($0.id) }) { return next }
            }
            if let firstIncomplete = areaLevels.first(where: { !completed.contains($0.id) }) { return firstIncomplete }
            if let firstIncomplete = Curriculum.levels.first(where: { !completed.contains($0.id) }) { return firstIncomplete }
            return last
        }
        return Curriculum.levels(in: .english).first ?? Curriculum.fallback[0]
    }
}

extension Notification.Name {
    static let progressStoreDidChange = Notification.Name("BrightSprout.progressStoreDidChange")
}