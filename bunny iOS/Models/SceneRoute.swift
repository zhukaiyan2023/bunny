import Foundation

/// A pure state machine that records every screen transition. The SpriteKit
/// `GameViewController` listens for changes and swaps scenes accordingly.
@MainActor
final class SceneRouter {
    static let shared = SceneRouter()

    private(set) var route: Route = .menu

    private init() {
        // Test hook: launch with `-route <value>` to land on a specific scene.
        // Supported: menu, achievements, parentGate, parentDashboard,
        // map:english, map:math, map:lifeSkills,
        // lesson:<levelId>, scene:<levelId>, reward:<levelId>:<stars>
        let args = ProcessInfo.processInfo.arguments
        NSLog("[bunny] launch args: \(args)")
        if let idx = args.firstIndex(of: "-route"), idx + 1 < args.count {
            let raw = args[idx + 1]
            NSLog("[bunny] routing to: \(raw)")
            route = Self.parseRoute(raw) ?? .menu
        }
    }

    private static func parseRoute(_ raw: String) -> Route? {
        if raw == "menu" { return .menu }
        if raw == "achievements" { return .achievements }
        if raw == "parentGate" { return .parentGate }
        if raw == "parentDashboard" { return .parentDashboard }
        if raw == "welcome" { return .welcome }
        if raw == "parentPrimer" { return .parentPrimer }
        if raw.hasPrefix("map:") {
            let area = String(raw.dropFirst(4))
            // Accept both PascalCase ("Math") and lower-case ("math") inputs.
            let candidates = [area, area.capitalized, area.uppercased()]
            for c in candidates {
                if let a = LearningArea(rawValue: c) { return .map(a) }
            }
        }
        if raw.hasPrefix("lesson:") {
            let id = String(raw.dropFirst(7))
            if let lvl = Curriculum.levels.first(where: { $0.id == id }) { return .lesson(lvl) }
        }
        if raw.hasPrefix("scene:") {
            let id = String(raw.dropFirst(6))
            if let lvl = Curriculum.levels.first(where: { $0.id == id }) { return .scene(lvl) }
        }
        if raw.hasPrefix("reward:") {
            let body = String(raw.dropFirst(7))
            let parts = body.split(separator: ":")
            if parts.count == 2,
               let lvl = Curriculum.levels.first(where: { $0.id == String(parts[0]) }),
               let stars = Int(parts[1]) {
                return .reward(lvl, stars)
            }
        }
        return nil
    }

    func go(_ destination: Route) {
        NSLog("[bunny] SceneRouter.go from \(route) to \(destination)")
        guard route != destination else { return }
        route = destination
        NotificationCenter.default.post(name: .sceneRouterDidChange, object: nil)
    }

    func goHome() { go(.menu) }
    func goMap(area: LearningArea) { go(.map(area)) }
    func goLesson(level: LevelDefinition) { go(.lesson(level)) }
    func goScene(level: LevelDefinition) { go(.scene(level)) }
    func goReward(level: LevelDefinition, stars: Int) { go(.reward(level, stars)) }
    func goParentGate() { go(.parentGate) }
    func goParent() { go(.parentDashboard) }
    func goAchievements() { go(.achievements) }
    func goWelcome() { go(.welcome) }
    func goParentPrimer() { go(.parentPrimer) }

    enum Route: Equatable {
        case menu
        case map(LearningArea)
        case lesson(LevelDefinition)
        case scene(LevelDefinition)
        case reward(LevelDefinition, Int)
        case parentGate
        case parentDashboard
        case achievements
        // Onboarding flow (S1-01..02)
        case welcome           // first-launch greeting
        case parentPrimer      // post-M01 parent setup primer
    }
}

extension Notification.Name {
    static let sceneRouterDidChange = Notification.Name("bunny.sceneRouterDidChange")
}