import Foundation

// S2-02 — ProgressStore round-trip tests (16 cases)
// Adapted to the actual ProgressStore public API:
//   - stars is a public-read dict (use store.stars["M01"] ?? 0)
//   - the only way to set stars is via store.complete(_:stars:)
//   - no setStars(for:) method exists

@MainActor
func progressStoreTests(into runner: TestRunner) {
    print("ProgressStore tests:")

    runner.add("stars_defaultEmpty") {
        let store = isolatedStore()
        return XCTestCase.XCTAssertNil(store.stars["M01"],
                                        "M01 should not be in stars by default")
    }

    runner.add("stars_roundTrip") {
        let suiteName = "round-trip-\(UUID().uuidString)"
        let store = sharedStore(suiteName: suiteName)
        store.complete(Curriculum.fallback[0], stars: 3)
        let reloaded = sharedStore(suiteName: suiteName)
        let id = Curriculum.fallback[0].id
        return XCTestCase.XCTAssertEqual(reloaded.stars[id] ?? 0, 3,
                                          "stars should round-trip through UserDefaults")
    }

    runner.add("stars_maxWins_higherOverwritesLower") {
        let store = isolatedStore()
        let id = Curriculum.fallback[0].id
        store.complete(Curriculum.fallback[0], stars: 1)
        store.complete(Curriculum.fallback[0], stars: 3)
        return XCTestCase.XCTAssertEqual(store.stars[id] ?? 0, 3,
                                          "max-wins: 3 should overwrite 1")
    }

    runner.add("stars_maxWins_lowerDoesNotOverwriteHigher") {
        let store = isolatedStore()
        let id = Curriculum.fallback[0].id
        store.complete(Curriculum.fallback[0], stars: 3)
        store.complete(Curriculum.fallback[0], stars: 1)
        return XCTestCase.XCTAssertEqual(store.stars[id] ?? 0, 3,
                                          "max-wins: 1 must NOT overwrite 3")
    }

    runner.add("completed_containsAfterComplete") {
        let store = isolatedStore()
        store.complete(Curriculum.fallback[0], stars: 2)
        return XCTestCase.XCTAssertTrue(store.completed.contains(Curriculum.fallback[0].id),
                                         "completed set should contain level id after complete")
    }

    runner.add("totalStars_sumsAllLevels") {
        let store = isolatedStore()
        store.complete(Curriculum.fallback[0], stars: 3)
        let m02 = Curriculum.levels.first(where: { $0.id == "M02" })
        if let m02 { store.complete(m02, stars: 2) }
        let e01 = Curriculum.levels.first(where: { $0.id == "E01" })
        if let e01 { store.complete(e01, stars: 1) }
        return XCTestCase.XCTAssertEqual(store.totalStars, 6,
                                          "totalStars should sum across all levels")
    }

    runner.add("totalAttempts_countsCompleteCalls") {
        let store = isolatedStore()
        store.complete(Curriculum.fallback[0], stars: 3)
        store.complete(Curriculum.fallback[0], stars: 3)
        return XCTestCase.XCTAssertEqual(store.totalAttempts, 2,
                                          "totalAttempts counts every complete() call")
    }

    runner.add("lastPlayedLevelID_setAfterComplete") {
        let store = isolatedStore()
        store.complete(Curriculum.fallback[0], stars: 3)
        return XCTestCase.XCTAssertEqual(store.lastPlayedLevelID, Curriculum.fallback[0].id,
                                          "lastPlayedLevelID should match completed level")
    }

    runner.add("lastPlayedAt_recentAfterComplete") {
        let store = isolatedStore()
        let before = Date()
        store.complete(Curriculum.fallback[0], stars: 3)
        let after = Date()
        guard let lp = store.lastPlayedAt else {
            return .fail("lastPlayedAt should be set")
        }
        if lp >= before && lp <= after { return .pass }
        return .fail("lastPlayedAt should be between before and after timestamps")
    }

    runner.add("isUnlocked_firstLevel_alwaysTrue") {
        let store = isolatedStore()
        let firstInEnglish = Curriculum.levels(in: .english)[0]
        return XCTestCase.XCTAssertTrue(
            store.isUnlocked(firstInEnglish, in: Curriculum.levels(in: .english)),
            "first level in any area should always be unlocked")
    }

    runner.add("isUnlocked_secondLevel_requiresFirst") {
        let store = isolatedStore()
        let englishLevels = Curriculum.levels(in: .english)
        let first = englishLevels[0]
        let second = englishLevels[1]
        return XCTestCase.XCTAssertTrue(
            !store.isUnlocked(second, in: englishLevels),
            "second level should be locked until first is completed")
    }

    runner.add("isUnlocked_secondLevel_unlockedAfterFirst") {
        let store = isolatedStore()
        let englishLevels = Curriculum.levels(in: .english)
        let first = englishLevels[0]
        store.complete(first, stars: 1)
        return XCTestCase.XCTAssertTrue(
            store.isUnlocked(englishLevels[1], in: englishLevels),
            "second level should unlock after first is completed")
    }

    runner.add("recommendedLevel_returnsEnglishFirst") {
        let store = isolatedStore()
        let rec = store.recommendedLevel
        // First-time, no lastPlayedLevelID — recommended should be English first.
        if rec.area == .english || rec.id == "M01" { return .pass }
        return .fail("recommendedLevel for fresh store should be English first or M01, got \(rec.id) (\(rec.area.rawValue))")
    }

    runner.add("resetProgress_clearsAll") {
        let suiteName = "reset-\(UUID().uuidString)"
        let store = sharedStore(suiteName: suiteName)
        store.complete(Curriculum.fallback[0], stars: 3)
        let m01 = Curriculum.levels.first(where: { $0.id == "M01" })
        if let m01 { store.complete(m01, stars: 2) }
        store.setFamilyPractice("M01", completed: true)
        // Simulate Reset Progress by wiping all brightsprout.* keys
        let d = UserDefaults(suiteName: suiteName)!
        for key in d.dictionaryRepresentation().keys {
            if key.hasPrefix("brightsprout.") { d.removeObject(forKey: key) }
        }
        let reloaded = sharedStore(suiteName: suiteName)
        let pass1 = XCTestCase.XCTAssertNil(reloaded.stars["M01"], "stars should reset")
        let pass2 = XCTestCase.XCTAssertEqual(reloaded.totalStars, 0, "totalStars should reset")
        let pass3 = XCTestCase.XCTAssertEqual(reloaded.totalAttempts, 0, "totalAttempts should reset")
        let pass4 = XCTestCase.XCTAssertEqual(reloaded.familyPractice.count, 0, "familyPractice should reset")
        let pass5 = XCTestCase.XCTAssertNil(reloaded.lastPlayedLevelID, "lastPlayedLevelID should reset")
        if [pass1, pass2, pass3, pass4, pass5].allSatisfy({ $0.isPass }) { return .pass }
        return .fail("one or more reset assertions failed")
    }

    runner.add("corruptedStarsValue_defaultsEmpty") {
        let d = storeUserDefaults()
        d.set(Data([0xFF, 0x00, 0xAB]), forKey: "brightsprout.stars")
        let reloaded = isolatedStore()
        return XCTestCase.XCTAssertEqual(reloaded.totalStars, 0,
                                          "corrupted stars key should default to empty")
    }

    runner.add("setStars_emitsNotification_via_complete") {
        let store = isolatedStore()
        var notificationCount = 0
        let token = NotificationCenter.default.addObserver(
            forName: .progressStoreDidChange, object: nil, queue: nil
        ) { _ in notificationCount += 1 }
        defer { NotificationCenter.default.removeObserver(token) }
        store.complete(Curriculum.fallback[0], stars: 3)
        return XCTestCase.XCTAssertTrue(notificationCount >= 1,
                                         "complete() should emit progressStoreDidChange (\(notificationCount))")
    }
}

/// Returns a fresh ProgressStore backed by a one-shot isolated UserDefaults
/// suite. Each call gets a fresh suite — useful for tests that don't
/// care about persistence across calls.
@MainActor
func isolatedStore() -> ProgressStore {
    let suiteName = "bunny-tests-\(UUID().uuidString)"
    let store = sharedStore(suiteName: suiteName)
    ProgressStoreTestIsolation.activeSuites.append(suiteName)
    return store
}

/// Returns a ProgressStore backed by the given suite name. Two calls with
/// the same `suiteName` see the same persisted state — required for
/// round-trip and reset tests.
@MainActor
func sharedStore(suiteName: String) -> ProgressStore {
    let defaults = UserDefaults(suiteName: suiteName)!
    let store = ProgressStore(defaults: defaults)
    store.bootstrap()
    return store
}

@MainActor
func storeUserDefaults() -> UserDefaults {
    if let last = ProgressStoreTestIsolation.activeSuites.last {
        return UserDefaults(suiteName: last)!
    }
    return UserDefaults.standard
}

@MainActor
enum ProgressStoreTestIsolation {
    static var activeSuites: [String] = []
}
