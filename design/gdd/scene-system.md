# Scene System — GDD

**System slug**: SYS-EXP-001
**Status**: Approved (v1.0)
**Pillars served**: All (cross-cutting)
**Last updated**: 2026-01

---

## Overview

The Scene System defines how every interactive screen in bunny is structured,
instantiated, transitioned, and torn down. It enforces a **single, consistent
lifecycle** across all 14 scene types so contributors can move between scenes
without learning a new pattern each time.

---

## Requirements

| ID | Requirement |
|---|---|
| **TR-SCENE-001** | Every playable screen MUST subclass `SKScene` (or a documented subclass like `RewardScene`). |
| **TR-SCENE-002** | Every scene MUST follow the standard lifecycle (init → didMove → update → touchesBegan/Moved/Ended → willMove). |
| **TR-SCENE-003** | A scene MUST NOT create another `SKScene` inline; all scene creation goes through `GameSceneFactory` or `GameViewController.makeScene(for:size:)`. |
| **TR-SCENE-004** | A scene MUST NOT retain notification observers past `willMove(from:)` — leak risk. |
| **TR-SCENE-005** | A scene MUST NOT perform synchronous network or disk I/O in `init(size:)` — first-frame budget. |
| **TR-SCENE-006** | A scene's update loop MUST complete in < 1 ms (typical) and < 3 ms (hard cap). |
| **TR-SCENE-007** | Multi-touch MUST be disabled (`isMultipleTouchEnabled = false` on the host SKView). One finger = one action. |
| **TR-SCENE-008** | All scene transitions MUST use one of the predefined helpers in `SKBridge` (no ad-hoc `SKTransition`). |

---

## Scene Catalog

The 14 scene types fall into 4 roles:

| Role | Scenes | Purpose |
|---|---|---|
| **Hub** | `MenuScene`, `AreaScene`, `LevelMapScene`, `LessonPlanScene` | Navigation + selection |
| **Gameplay** | `MathGameScene`, `EnglishGameScene`, `LifeSkillsGameScene`, `ImmersiveMissionScene` | The actual task |
| **Meta** | `RewardScene`, `AchievementsScene` | Feedback + recognition |
| **Parent** | `ParentGateScene`, `ParentDashboardScene` | Adult-only flow |

---

## Lifecycle Contract

```swift
class MyScene: SKScene {
    // 1. Pure setup: no GameViewController, no UserDefaults, no scene router
    override init(size: CGSize) {
        super.init(size: size)
        buildLayout()
    }
    required init?(coder aDecoder: NSCoder) { fatalError() }

    // 2. Subscribe to notifications, kick off animations, start gameplay
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        SpeechService.shared.speak(instruction)
    }

    // 3. Gameplay tick — keep it cheap
    override func update(_ currentTime: TimeInterval) {
        // physics, timers, idle animations
    }

    // 4. Touch handling — single-finger only
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        handleTap(at: touch.location(in: self))
    }

    // 5. Teardown: cancel actions, stop audio, remove observers, persist
    override func willMove(from view: SKView) {
        removeAllActions()
        removeAllChildren()
        ProgressStore.shared.flush()
    }
}
```

---

## Scene Factory

```swift
enum GameSceneFactory {
    static func makeScene(size: CGSize, level: LevelDefinition) -> SKScene {
        switch level.area {
        case .math:       return MathGameScene(size: size, level: level)
        case .english:    return EnglishGameScene(size: size, level: level)
        case .lifeSkills: return LifeSkillsGameScene(size: size, level: level)
        }
    }
}
```

The factory is the **only** place that decides which concrete scene class to
instantiate for a given level. New scene types extend the factory's switch.

---

## Source

- All files in `bunny iOS/Scenes/`
- `bunny iOS/UI/SKBridge.swift` (transition helpers)
- `bunny iOS/GameViewController.swift` (host + transition driver)

---

## Anti-Patterns

| Pattern | Why wrong |
|---|---|
| `SKScene(size: ...)` inline in a button handler | Bypasses routing, breaks back-stack |
| `NotificationCenter.default.addObserver(forName: ...)` without storing token | Memory leak across scene swaps |
| `removeAllChildren()` in `didMove(to:)` | Wasted work — nodes released with parent |
| Strong self in a closure retained past `willMove` | Memory leak |
| Calling `SpeechService.speak` before `didMove(to:)` | Audio context not yet set up |

---

## Acceptance Criteria

- [ ] All 14 scenes pass a code review against the lifecycle contract
- [ ] Switching between every pair of scenes via the router works without crashes
- [ ] No scene retains observers past its deallocation (verified with memory graph)
- [ ] First frame of every scene renders within 200 ms of `presentScene`
- [ ] `update(_:)` cost measured at < 3 ms in any scene

---

## Open Questions

- Should scenes be able to declare their own custom transition? Currently
  no — they go through `SKBridge` defaults. (Tracked as future work.)

Last updated: 2026-01
