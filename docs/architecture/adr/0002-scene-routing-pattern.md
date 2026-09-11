# ADR-0002: Scene Routing via Singleton + NotificationCenter

**Status**: Accepted
**Date**: 2026-01
**Deciders**: bunny team

---

## Context

bunny has 14 scene types that the user navigates between (Menu, Area
hub, Level map, Lesson plan, Gameplay, Reward, Achievements, Parent
gate, Parent dashboard, Onboarding). We need a single, consistent way
for any scene, button, or service to request a navigation change
without knowing about the underlying `SKView`, transitions, or
device specifics.

Requirements:

- Any code can READ the current route.
- Navigation code can WRITE a new route.
- The view layer (host) is the only place that actually swaps scenes.
- The system must support parameterized routes (e.g., a specific level).
- The system must avoid retaining scene references (memory leaks across scene swaps).

---

## Decision

Use a **`SceneRouter` singleton** holding an exhaustive `Route` enum.
Route changes are published via `NotificationCenter.default` with a
single notification name: `.sceneRouterDidChange`. The host
`GameViewController` is the only subscriber that calls
`SKView.presentScene(_:transition:)`.

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

final class SceneRouter {
    static let shared = SceneRouter()
    private(set) var route: Route

    func go(_ next: Route) {
        guard next != route else { return }
        route = next
        NotificationCenter.default.post(name: .sceneRouterDidChange, object: nil)
    }
}
```

Detailed design: `design/gdd/routing-system.md`.

---

## Alternatives Considered

### A. UIKit-style UINavigationController
- **Pros**: well-known pattern, free back-stack.
- **Cons**: not idiomatic for SpriteKit; forces a UIKit dependency per platform; doesn't extend cleanly to macOS / tvOS.
- **Why rejected**: SpriteKit's scene graph is the right abstraction; introducing a navigation controller pulls us toward UIKit, which we explicitly limit to the host `GameViewController`.

### B. Delegate-based routing
- **Pros**: type-safe, compile-time checked.
- **Cons**: every scene needs a back-pointer to a delegate; doesn't scale across scenes; forces tight coupling.
- **Why rejected**: singletons + NotificationCenter is simpler for our scale and matches how the existing code already works.

### C. SwiftUI NavigationStack
- **Pros**: modern, declarative.
- **Cons**: doesn't integrate with SpriteKit scene graphs cleanly; tvOS focus integration is rough.
- **Why rejected**: SpriteKit owns the navigation surface in v1.

### D. Combine / async sequences
- **Pros**: modern, composable.
- **Cons**: overkill for a single notification channel.
- **Why rejected**: NotificationCenter is sufficient and idiomatic for Apple-platform code.

---

## Consequences

### Positive
- Single source of truth for "what scene is on screen"
- Any scene, button, or service can request navigation
- Host layer owns the actual `SKView` swap (single responsibility)
- Parameterized routes are type-safe via enum associated values
- NotificationCenter is built-in, no third-party dependency

### Negative
- One global singleton (mitigated — three allowed singletons total)
- No automatic back-stack — `back()` is hand-rolled in `SceneRouter`
- Notification observer must store the returned token to avoid leaking

### Neutral
- Scenes must always go through `SceneRouter.go(...)`; never call
  `SKView.presentScene` directly. Enforced by code review and
  `control-manifest.md`.

---

## References

- `design/gdd/routing-system.md`
- `design/gdd/scene-system.md`
- `bunny iOS/Models/SceneRoute.swift`
- `bunny iOS/GameViewController.swift`

Last updated: 2026-01
