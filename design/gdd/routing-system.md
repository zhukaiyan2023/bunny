# Routing System — GDD

**System slug**: SYS-EXP-002
**Status**: Approved (v1.0)
**Pillars served**: Pillar 5 (Adult-gated — routing separates child / parent paths)
**Last updated**: 2026-01

---

## Overview

The Routing System is the **single source of truth** for "what scene is on
screen right now". It is a singleton (`SceneRouter.shared`) that holds a
`Route` enum value, publishes change events via `NotificationCenter`, and
relies on `GameViewController` to actually swap scenes on its `SKView`.

Decoupling the **what** (route value) from the **how** (view swap) means
any scene, any service, or any UI button can request a navigation change
without knowing about `SKView`, transitions, or device specifics.

---

## Requirements

| ID | Requirement |
|---|---|
| **TR-ROUT-001** | The system MUST be a single shared instance (`SceneRouter.shared`). |
| **TR-ROUT-002** | The route type MUST be an exhaustive enum with associated values for parameterized routes. |
| **TR-ROUT-003** | Route changes MUST be published via `NotificationCenter.default.post(name: .sceneRouterDidChange, ...)`. |
| **TR-ROUT-004** | `GameViewController` MUST be the only subscriber that calls `SKView.presentScene(_:transition:)`. |
| **TR-ROUT-005** | Any code may READ the current route via `SceneRouter.shared.route`. |
| **TR-ROUT-006** | Only "navigation" code (button handlers, scene lifecycle, debug tools) may WRITE the route via `SceneRouter.shared.go(...)`. |
| **TR-ROUT-007** | Writing a route that equals the current route MUST be a no-op (no notification fires, no transition). |
| **TR-ROUT-008** | The system MUST NOT retain scene references — the route value carries only data, not scene objects. |

---

## Route Enum

```swift
extension SceneRouter {
    enum Route: Equatable {
        case menu
        case map(area: LearningArea)
        case lesson(level: LevelDefinition)
        case scene(level: LevelDefinition)
        case reward(level: LevelDefinition, stars: Int)
        case parentGate
        case parentDashboard
        case achievements
    }
}
```

The `Route` enum is **deeply equatable** so the no-op write check works for
parameterized routes (e.g., going to the same level is a no-op).

---

## API

```swift
final class SceneRouter {
    static let shared = SceneRouter()

    private(set) var route: Route

    func go(_ next: Route) {
        guard next != route else { return }
        route = next
        NotificationCenter.default.post(name: .sceneRouterDidChange, object: nil)
    }

    func back() {
        // Pops to a sensible parent based on current route
        // (Implementation: see SceneRouter.swift)
    }
}

extension Notification.Name {
    static let sceneRouterDidChange = Notification.Name("bunny.sceneRouter.didChange")
}
```

---

## How a Scene Swap Actually Happens

```
Button tapped in MenuScene
        │
        ▼
MenuScene calls SceneRouter.shared.go(.map(area: .math))
        │
        ▼
SceneRouter updates `route`, posts .sceneRouterDidChange
        │
        ▼
GameViewController's notification observer fires
        │
        ▼
GameViewController.makeScene(for: route, size: ...)
        │
        ▼
SKView.presentScene(scene, transition: SKTransition.fade(0.28))
        │
        ▼
Old scene's willMove(from:) runs → cleanup
New scene's didMove(to:) runs → setup
```

---

## Back Navigation

| From | "Back" goes to |
|---|---|
| `.map(area:)` | `.menu` |
| `.lesson(level:)` | `.map(area: level.area)` |
| `.scene(level:)` | `.lesson(level: level)` |
| `.reward(level:_, stars:_)` | `.map(area: level.area)` (no replay-back) |
| `.parentGate` | previous route (preserved) |
| `.parentDashboard` | previous route (preserved) |
| `.achievements` | `.menu` |
| `.menu` | (no-op — exits app or no-op) |

---

## Source

- `bunny iOS/Models/SceneRoute.swift` — enum + singleton
- `bunny iOS/GameViewController.swift` — observer + presentScene

---

## Anti-Patterns

| Pattern | Why wrong |
|---|---|
| `SKView.presentScene(...)` in a button handler | Bypasses routing |
| Holding `SKScene` references in `SceneRouter` | Lifetime confusion |
| Multiple observers of `.sceneRouterDidChange` | One observer only — in `GameViewController` |
| Mutating `route` directly (bypassing `go(_:)`) | Notification doesn't fire, scene doesn't swap |

---

## Acceptance Criteria

- [ ] Every navigation in the app flows through `SceneRouter.shared.go(...)`
- [ ] No scene directly calls `SKView.presentScene`
- [ ] XCTest verifies that `go(.menu)` from `.menu` is a no-op (no notification)
- [ ] XCTest verifies route change fires exactly one notification per change
- [ ] Memory graph: no scene is retained by `SceneRouter`

---

## Open Questions

None.

Last updated: 2026-01
