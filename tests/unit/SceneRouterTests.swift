import Foundation

// S2-04 — SceneRouter route transition tests (10 cases)
// Story: production/epics/epic-persistence-tests/story-004-scenerouter-tests.md

@MainActor
func sceneRouterTests(into runner: TestRunner) {
    print("SceneRouter tests:")

    runner.add("initialRouteIsMenu") {
        XCTestCase.XCTAssertEqual(SceneRouter.shared.route, .menu,
                                   "default route should be .menu")
    }

    runner.add("goChangesRoute") {
        let router = SceneRouter.shared
        let original = router.route
        defer { router.go(original) }
        router.go(.achievements)
        return XCTestCase.XCTAssertEqual(router.route, .achievements,
                                          "route should be .achievements after go")
    }

    runner.add("goSameRouteIsNoOp") {
        let router = SceneRouter.shared
        router.go(.menu)  // baseline
        var fired = 0
        let token = NotificationCenter.default.addObserver(
            forName: .sceneRouterDidChange, object: nil, queue: nil
        ) { _ in fired += 1 }
        defer { NotificationCenter.default.removeObserver(token) }

        router.go(.menu)  // same as current — should be no-op
        return XCTestCase.XCTAssertEqual(fired, 0,
                                          "go to current route must not fire notification")
    }

    runner.add("goDifferentRouteFiresNotification") {
        let router = SceneRouter.shared
        router.go(.menu)
        var fired = 0
        let token = NotificationCenter.default.addObserver(
            forName: .sceneRouterDidChange, object: nil, queue: nil
        ) { _ in fired += 1 }
        defer { NotificationCenter.default.removeObserver(token) }

        router.go(.achievements)
        return XCTestCase.XCTAssertEqual(fired, 1,
                                          "go to different route must fire exactly 1 notification")
    }

    runner.add("parameterizedRoutesAreEquatable") {
        let m01 = Curriculum.levels.first(where: { $0.id == "M01" })!
        let m02 = Curriculum.levels.first(where: { $0.id == "M02" })!
        let r1: SceneRouter.Route = .scene(m01)
        let r2: SceneRouter.Route = .scene(m02)
        let r3: SceneRouter.Route = .scene(m01)
        if r1 == r2 { return .fail("different levels should produce different routes") }
        if r1 != r3 { return .fail("same level should produce equal routes") }
        return .pass
    }

    runner.add("goHelpersRouteCorrectly") {
        let router = SceneRouter.shared
        let original = router.route
        defer { router.go(original) }

        router.goMap(area: .math)
        if router.route != .map(.math) { return .fail("goMap should set .map") }
        router.goAchievements()
        if router.route != .achievements { return .fail("goAchievements should set .achievements") }
        router.goParentGate()
        if router.route != .parentGate { return .fail("goParentGate should set .parentGate") }
        router.goHome()
        if router.route != .menu { return .fail("goHome should set .menu") }
        return .pass
    }

    runner.add("goScene_levelRoutesCorrectly") {
        let router = SceneRouter.shared
        let original = router.route
        defer { router.go(original) }

        guard let m05 = Curriculum.levels.first(where: { $0.id == "M05" }) else {
            return .fail("M05 should exist in the curriculum")
        }
        router.goScene(level: m05)
        if router.route != .scene(m05) {
            return .fail("goScene should set .scene with the level")
        }
        return .pass
    }

    runner.add("goReward_routesCorrectly") {
        let router = SceneRouter.shared
        let original = router.route
        defer { router.go(original) }

        guard let m10 = Curriculum.levels.first(where: { $0.id == "M10" }) else {
            return .fail("M10 should exist in the curriculum")
        }
        router.goReward(level: m10, stars: 3)
        if router.route != .reward(m10, 3) {
            return .fail("goReward should set .reward(level, stars)")
        }
        return .pass
    }

    runner.add("goLesson_routesCorrectly") {
        let router = SceneRouter.shared
        let original = router.route
        defer { router.go(original) }

        guard let e01 = Curriculum.levels.first(where: { $0.id == "E01" }) else {
            return .fail("E01 should exist in the curriculum")
        }
        router.goLesson(level: e01)
        if router.route != .lesson(e01) {
            return .fail("goLesson should set .lesson with the level")
        }
        return .pass
    }

    runner.add("goParent_routesCorrectly") {
        let router = SceneRouter.shared
        let original = router.route
        defer { router.go(original) }

        router.goParent()
        if router.route != .parentDashboard {
            return .fail("goParent should set .parentDashboard")
        }
        return .pass
    }
}
