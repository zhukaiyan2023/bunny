# Story S2-04 — SceneRouter Route Transition Tests

**Epic**: EPIC-002 — Persistence Hardening + Unit Test Coverage
**Status**: Ready (depends on S2-01)
**GDD req**: TR-ROUT-001..008
**ADR**: ADR-0002 (singleton + NotificationCenter)
**Story type**: Test
**Acceptance test**: all tests pass in CI

---

## Context

`SceneRouter` is the singleton that drives navigation. The no-op-on-equal-route
rule and the single-notification-per-change rule are easy to break and would
cause subtle bugs (double scenes, missed transitions, ghost notifications).
We need explicit XCTest coverage.

---

## Acceptance Criteria

- [ ] `tests/unit/SceneRouterTests.swift` exists in the `bunnyTests`
  target
- [ ] Test cases:

| Test | Description |
|---|---|
| `test_initialRouteIsMenu` | After `reset()`, `route` is `.menu` |
| `test_goChangesRoute` | `go(.achievements)` → `route == .achievements` |
| `test_goSameRouteIsNoOp` | `go(.menu)` from `.menu` does NOT post a notification |
| `test_goDifferentRouteFiresNotification` | `go(.achievements)` from `.menu` fires `.sceneRouterDidChange` exactly once |
| `test_parameterizedRoutesAreEquatable` | `Route.scene(level: m01)` != `Route.scene(level: m02)` |
| `test_backFromMapGoesToMenu` | `back()` from `.map(area: .math)` returns to `.menu` |
| `test_backFromLessonGoesToMap` | `back()` from `.lesson(level: m01)` returns to `.map(area: .math)` |
| `test_backFromSceneGoesToLesson` | `back()` from `.scene(level: m01)` returns to `.lesson(level: m01)` |
| `test_backFromMenuIsNoOp` | `back()` from `.menu` does nothing |
| `test_routerDoesNotRetainSceneReferences` | Setting a route never captures an `SKScene` (no leaked objects across many route changes) |

- [ ] All 10 tests pass in CI
- [ ] Tests use `NotificationCenter.default.notifications(named:)` async
  sequence (iOS 15+) or a synchronous observer count

---

## Implementation Notes

```swift
final class SceneRouterTests: XCTestCase {
    var sut: SceneRouter!

    override func setUp() {
        super.setUp()
        SceneRouter.shared.resetForTesting()
        sut = SceneRouter.shared
    }

    func test_goSameRouteIsNoOp() {
        var fired = 0
        let token = NotificationCenter.default.addObserver(
            forName: .sceneRouterDidChange, object: nil, queue: nil
        ) { _ in fired += 1 }
        defer { NotificationCenter.default.removeObserver(token) }

        // Initial route is .menu
        sut.go(.menu)
        XCTAssertEqual(fired, 0)
    }

    func test_goDifferentRouteFiresNotification() {
        var fired = 0
        let token = NotificationCenter.default.addObserver(
            forName: .sceneRouterDidChange, object: nil, queue: nil
        ) { _ in fired += 1 }
        defer { NotificationCenter.default.removeObserver(token) }

        sut.go(.achievements)
        XCTAssertEqual(fired, 1)
    }

    // ... remaining 8 tests
}
```

`SceneRouter` may need a `resetForTesting()` method that resets `route`
back to `.menu` without firing a notification. This is **only** used by
tests; production code never calls it.

---

## Engine Risk

**Low** — `SceneRouter` is pure logic.

---

## Test Evidence Path

This file IS the test evidence. CI run logs show 10 tests passed.
