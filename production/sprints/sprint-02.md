# Sprint 02 — Wire SceneRouter into the Live App

**Sprint window**: 2026-01-29 → 2026-02-11 (2 weeks)
**Theme**: Stop being a SpriteKit shell. Make the actual game run on the actual device.
**Goal**: `xcodebuild + open in Xcode + run on iPad Simulator` shows the welcome scene, M01, the reward scene, the parent primer, and the menu — driven by SceneRouter.

---

## Why this sprint exists

After Sprint 1 the codebase has 14 SKScene subclasses, 50 levels, a SceneRouter,
a ProgressStore, a SpeechService, a curriculum validator, 52 unit tests, and a
green CI. But the actual `bunny iOS/GameViewController.swift` was still calling
`GameScene.newGameScene()` — Apple's template bouncing shape demo. The bunny
code was compiled but **never displayed**.

Sprint 2 closes that gap. After this sprint, `xcodebuild build && open
bunny.xcodeproj && ⌘R` shows the real game.

---

## Capacity

- 1 developer, 2 weeks
- 25 story points
- Story-point budget: heavy code-touching week + heavy test-and-verify week

---

## Committed Stories

### EPIC-WIRE — SceneRouter live wiring
| ID | Title | Pts | Status |
|---|---|---|---|
| **W1** | iOS GameViewController: replace `GameScene.newGameScene()` with SceneRouter dispatch | 3 | Done |
| **W2** | macOS GameViewController: revert to Apple template (out of scope for Sprint 2) | 1 | Done |
| **W3** | tvOS GameViewController: revert to Apple template (ADR-0006 deferred to Sprint 3) | 1 | Done |
| **W4** | BunnyAppDelegate + viewDidLoad: initial route based on `onboardingComplete` | 1 | Done (in W1) |
| **W5** | RewardScene: auto-route to .parentPrimer after first M01 completion | 1 | Done |
| **W6** | ParentDashboard: add "Reset Progress" button → `resetAllProgress()` → `.welcome` | 2 | Done |
| **W7** | Unit tests for routing logic (`onboardingComplete`, `attempts["M01"]`) | 2 | Done |
| **W8** | CI: enable tvOS build matrix (when SDK is installed) | 1 | Deferred |

**Total committed**: 12 points (well within capacity)

### EPIC-VERIFY — Build, test, ship
| ID | Title | Pts | Status |
|---|---|---|---|
| **V1** | iOS Simulator manual play-through: welcome → M01 → reward → primer → menu | 2 | Deferred (requires physical / simulator launch) |
| **V2** | Confirm xcodebuild iOS / macOS green, 52 tests pass | 1 | Done |

**Total**: 3 points

---

## Out of Sprint (parked, becomes Sprint 3)

- **macOS scene code sharing** — requires pbxproj surgery to add synchronized
  folders for `bunny iOS/Models/`, `Scenes/`, `Services/`, `UI/` to the macOS
  target. Or alternatively, restructure so model/scene code lives in
  `bunny Shared/`. Both are tracked as a Sprint 3 first story.
- **tvOS focus proxy** — ADR-0006.
- **Curriculum validator (S7-01..05)** — XCTest that validates `levels.json` at
  build time. We already have a Python validator in CI; the XCTest version is
  lower priority.
- **Accessibility audit (S3-01..05)** — Sprint 3.

---

## Implementation Notes

### iOS GameViewController

The new `bunny iOS/GameViewController.swift` (140 lines):

```swift
final class GameViewController: UIViewController {
    private var observation: NSObjectProtocol?
    private let host = SKView(frame: .zero)

    override func viewDidLoad() {
        ProgressStore.shared.bootstrap()
        if !hasLaunchRoute() {
            let initial: SceneRouter.Route = ProgressStore.shared.onboardingComplete
                ? .menu : .welcome
            SceneRouter.shared.go(initial)
        }
        present(SceneRouter.shared.route, transition: nil)
        observation = NotificationCenter.default.addObserver(
            forName: .sceneRouterDidChange, object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.present(SceneRouter.shared.route, transition: SKTransition.fade(withDuration: 0.28))
        }
    }

    private func makeScene(for route: SceneRouter.Route, size: CGSize) -> SKScene {
        switch route {
        case .menu: return MenuScene(size: size)
        case .map(let area): return AreaScene(size: size, area: area)
        case .lesson(let level): return LessonPlanScene(size: size, level: level)
        case .scene(let level): return GameSceneFactory.makeScene(size: size, level: level)
        case .reward(let level, let stars): return RewardScene(size: size, level: level, stars: stars)
        case .parentGate: return ParentGateScene(size: size)
        case .parentDashboard: return ParentDashboardScene(size: size)
        case .achievements: return AchievementsScene(size: size)
        case .welcome: return WelcomeScene(size: size)
        case .parentPrimer: return ParentPrimerScene(size: size)
        }
    }
}
```

The single `makeScene` switch is the audit point for new routes. Adding a
new route requires exactly one new `case` here — already the design in
ADR-0002.

### macOS / tvOS

These targets still show Apple's `GameScene` template because their
Xcode membership does **not** include `bunny iOS/Models/` etc. Either:
1. pbxproj: add four synchronized folder entries for the iOS subfolders.
2. Restructure: move model + scene + service code into `bunny Shared/`.

Either approach is a real Sprint 3 story with non-trivial pbxproj risk.

### RewardScene → ParentPrimer hook

```swift
override func didMove(to view: SKView) {
    buildBackground(); buildHeader(); buildStars(); buildConfetti()
    buildActionButtons()
    SpeechService.shared.speak("You did it, " + level.title + "!")
    if level.id == "M01", ProgressStore.shared.attempts["M01"] == 1 {
        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.6),
            SKAction.run { SceneRouter.shared.goParentPrimer() },
        ]))
    }
}
```

2.6-second delay so the confetti and the star animation complete before
the transition fires. After the second M01 completion, `attempts["M01"]
== 2`, so the hook doesn't re-fire.

### ParentDashboard Reset Progress

New `buildResetButton()` method on ParentDashboardScene. Wired into
`didMove(to:)`. Calls `ProgressStore.shared.resetAllProgress()` (which
wipes all `brightsprout.*` keys and resets `onboardingComplete` to
false) then routes to `.welcome`. Next launch lands in onboarding again.

---

## Risks

| Risk | Mitigation |
|---|---|
| pbxproj surgery to share scenes with macOS/tvOS is risky | Deferred to Sprint 3 with a dedicated story |
| RewardScene's automatic route might confuse users who expect to navigate manually | 2.6s delay before transition; `Home` button still works |
| ParentDashboard reset wipes progress — irreversible | Button is behind the parent gate (`ParentGateScene` first) |
| `attempts["M01"] == 1` is a fragile signal if M01's id changes | Documented in `design/gdd/onboarding-system.md` |

---

## Demo at Sprint Review

1. Open `bunny.xcodeproj` in Xcode.
2. Select iPhone 15 simulator, ⌘R.
3. See `WelcomeScene` with Pip waving + TTS.
4. Tap anywhere → M01 (`Bakery Box Rescue`).
5. Solve the puzzle (or just tap some numbers + Check) → `RewardScene`.
6. After ~2.6s, auto-route to `ParentPrimerScene`.
7. Tap "Later" → `MenuScene`.
8. Repeat — no more onboarding (welcome is skipped).
9. Tap "For Grown-Ups" → `ParentGateScene` → `ParentDashboardScene`.
10. Tap "Reset Progress" → next launch lands in welcome again.

---

Last updated: 2026-01
