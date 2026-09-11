# SpriteKit Scene Lifecycle — bunny Patterns

Last verified: 2026-01

This document is the canonical reference for how every `SKScene` in bunny should
initialize, accept input, run its update loop, transition out, and clean up.
Following these patterns keeps scenes consistent, testable, and easy to swap.

## The Scene Protocol

Every scene in `bunny iOS/Scenes/` should conform (by base class behavior) to
this implicit lifecycle:

```
┌────────────────────────────────────────────────────────────────┐
│  init(size:)                                                    │
│    • Pure setup: allocate nodes, build layout, set z-order     │
│    • NO calls to GameViewController or NotificationCenter        │
│    • NO reading from UserDefaults (use ProgressStore injection) │
└────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────┐
│  didMove(to:)                                                    │
│    • Subscribe to scene-router notifications                    │
│    • Trigger animations, ambient particles, ambient audio       │
│    • Begin gameplay (countdown, prompt, etc.)                   │
└────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────┐
│  update(_ currentTime:)                                         │
│    • Gameplay tick (timer, physics, AI)                        │
│    • Idle logic, hint animations                               │
│    • MUST be cheap (<1ms); heavy work goes in background tasks │
└────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────┐
│  touchesBegan / touchesMoved / touchesEnded                     │
│    • Translate raw touch into gameplay event                    │
│    • For reward/UI scenes: forward to SKButton                 │
└────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────┐
│  willMove(from:)                                                 │
│    • Cancel pending actions (removeAllActions)                  │
│    • Stop audio (SKAudioNode.autoplayLooped = false)            │
│    • Remove notification observers                             │
│    • Persist any in-flight progress (ProgressStore.flush)      │
└────────────────────────────────────────────────────────────────┘
```

## Scene Factory and Routing

All scenes are created through **`GameSceneFactory.makeScene(size:level:)`** for
level-specific scenes, or directly by `GameViewController.makeScene(for:size:)`
for menu / map / lesson / reward / parent-gate / parent-dashboard / achievements
scenes.

Routing is driven by `SceneRouter.shared.route`, which fires
`.sceneRouterDidChange` on `NotificationCenter.default`. `GameViewController`
listens and calls `host.presentScene(scene, transition:)`.

```
SceneRouter.route changes
        │
        ▼
NotificationCenter .sceneRouterDidChange
        │
        ▼
GameViewController.present(_:)
        │
        ├─ build new SKScene (factory or direct)
        ├─ SKTransition.fade(withDuration: 0.28)
        └─ host.presentScene(scene, transition:)
```

**NEVER** create a scene via `SKScene(size: ...)` inline inside a button handler.
Always go through the router so the routing logic is centralized.

## Transitions

| Use case | Transition | Duration |
|---|---|---|
| Menu ↔ AreaMap | `SKTransition.fade` | 0.28s |
| AreaMap → LessonPlan | `SKTransition.push(direction: .left)` | 0.32s |
| LessonPlan → GameScene | `SKTransition.push(direction: .left)` | 0.32s |
| GameScene → Reward | `SKTransition.crossFade` | 0.45s |
| Reward → AreaMap | `SKTransition.push(direction: .right)` | 0.32s |
| Any → ParentGate | `SKTransition.doorway(...)` | 0.4s |
| Any → ParentDashboard | `SKTransition.doorway(...)` | 0.4s |

(All defined as static helpers in `SKBridge.swift`.)

## Memory Management

- Each scene owns its children; when the scene is replaced, the old one is
  released and ARC deallocates its child node tree.
- `SKTexture` references are held by `SKTextureAtlas` which caches; do NOT
  pre-load textures manually.
- Audio nodes are stopped in `willMove(from:)` to free the underlying
  `AVAudioPlayer`.
- Notification observers registered with `NotificationCenter.default.addObserver(forName:object:queue:using:)`
  must store the returned `NSObjectProtocol` token and `removeObserver(token)`
  in `willMove(from:)`.

## Anti-Patterns

| Pattern | Why it's wrong |
|---|---|
| Singleton services accessed inside `init(size:)` | Couples scene to service initialization order |
| Hardcoded scene size | Breaks orientation changes and iPad split view |
| `SKView.presentScene(scene)` inside a scene | Bypasses `SceneRouter`, breaks back-stack |
| Manual `removeAllChildren()` in `didMove(to:)` | Wastes work — nodes are released with their parent |
| `NotificationCenter.default.post(...)` from `init` | Fires before observers can subscribe |
| Strong self capture in closures retained across scenes | Memory leak across scene swaps |

## Testing Hooks

Every scene exposes an internal-only `sceneDidFinish` completion handler (via
`SKBridge`) that integration tests can wait on. See `tests/integration/` for
examples (to be authored in milestone 2).

Last verified: 2026-01
