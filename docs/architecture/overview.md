# Architecture Overview — bunny

**Status**: Approved (v1.0)
**Last updated**: 2026-01
**Engine**: SpriteKit (iOS 26.5 / macOS 26.5 / tvOS 26.5)
**Language**: Swift 5.0

---

## 1. Goals & Constraints

### Goals
- **One codebase, three platforms** (iOS, macOS, tvOS) with zero source duplication for scenes
- **Zero third-party dependencies** — everything ships with Apple SDKs
- **Local-only state** — no network calls, no analytics, no cloud sync (Pillar 4)
- **Calm, accessible, predictable** — consistent scene lifecycle, no surprises (Pillars 1, 4, 5)
- **Testable core** — `ProgressStore`, `SceneRouter`, `Curriculum` are pure logic with no UI dependencies

### Constraints
- **3-target Xcode project** — cannot assume a single-platform build
- **SpriteKit-only rendering** — no custom Metal shaders, no SceneKit
- **No SPM dependencies** — every addition requires an ADR
- **iOS 26.5 deployment minimum** — gives us access to the latest SpriteKit + Swift Concurrency

---

## 2. High-Level Architecture

bunny is a **single-window, scene-graph application**. One `SKView` hosts
one `SKScene` at a time; the scene swaps when the user navigates.

```
┌─────────────────────────────────────────────────────────────┐
│  App Lifecycle                                                │
│  ┌────────────────┐                                          │
│  │ AppDelegate    │ sets up AVAudioSession, log redirection   │
│  │ SceneDelegate  │ (iOS only) provides the window            │
│  └───────┬────────┘                                          │
│          ▼                                                   │
│  ┌────────────────┐                                          │
│  │ GameView       │ (UIView/NSView per platform)              │
│  │ Controller     │ hosts SKView, listens to SceneRouter     │
│  └───────┬────────┘                                          │
│          ▼                                                   │
│  ┌──────────────────────────────────────────────┐            │
│  │ SKView  (60 fps, no multi-touch)              │            │
│  │  └─→ SKScene  (one at a time)                 │            │
│  │       └─→ SKNode tree                         │            │
│  └──────────────────────────────────────────────┘            │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  Cross-Cutting Services                                      │
│  ─ SceneRouter (singleton)        — drives navigation        │
│  ─ ProgressStore (singleton)      — UserDefaults wrapper    │
│  ─ SpeechService (singleton)      — TTS narration           │
│  ─ SKBridge                       — motion, transitions     │
│  ─ SKTheme                        — colors, fonts, sizes    │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Layered View

bunny is structured into **5 layers**, top-down. Lower layers MUST NOT
depend on higher layers.

| Layer | Responsibility | Examples |
|---|---|---|
| **Platform** | UIKit / AppKit / TVKit hosts | `GameViewController` per target |
| **Routing** | Navigation, scene selection | `SceneRouter`, `SceneRoute` |
| **Scene** | Interactive screens, game loop | 14 `SKScene` subclasses |
| **UI** | Themed primitives | `SKTheme`, `SKButton`, `SKCard`, `SKHUD` |
| **Model** | Data + business logic | `Curriculum`, `ProgressStore`, models |
| **Service** | Cross-cutting singletons | `SpeechService`, `SKBridge` |

---

## 4. System Map

The 16 systems documented in `design/systems-index.md` map to the 6
layers as follows:

```
Platform ──── Platform System (SYS-FOUND-001)
              Localization System (SYS-FOUND-003, v2 stub)
              Accessibility System (SYS-FOUND-004, cross-cutting)

Routing ───── Routing System (SYS-EXP-002)

Scene ─────── Scene System (SYS-EXP-001)
              Onboarding System (SYS-PLAYER-001)
              Math / English / Life Skills Systems (SYS-GP-001/002/003)
              Reward System (SYS-GP-004)
              Progression System (SYS-GP-005)
              Parent System (SYS-PLAYER-002)

UI ────────── UI System (SYS-EXP-003)

Model ─────── Curriculum System (SYS-CONT-001)
              Persistence System (SYS-FOUND-002)

Service ───── Audio System (SYS-EXP-004)
```

---

## 5. Key Architectural Decisions

| ADR | Decision | Status |
|---|---|---|
| ADR-0001 | Engine pin: SpriteKit on iOS 26.5 / Swift 5.0 | Accepted |
| ADR-0002 | Singleton + NotificationCenter routing pattern | Accepted |
| ADR-0003 | `UserDefaults` over Core Data for all persistence | Accepted |
| ADR-0004 | Single Xcode project, three targets, shared scene code | Accepted |
| ADR-0005 | Curriculum as JSON data, not Swift literals | Accepted |
| ADR-0006 | tvOS focus engine via `UIFocusEnvironment` proxy | Accepted (deferred impl) |
| ADR-0007 | Zero third-party Swift dependencies | Accepted |

(Full ADRs in `docs/architecture/adr/`.)

---

## 6. Module Boundaries

### 6.1 Singleton Services

Three singleton services exist: `SceneRouter`, `ProgressStore`,
`SpeechService`. They are the **only** globals allowed.

Why singletons?
- They are inherently cross-cutting (every scene reads them)
- Wrapping them in DI for a 36-file app would add ceremony without benefit
- They are testable via protocol indirection (when tests are added)

### 6.2 Notification Surfaces

```
NotificationCenter.default
  ├── .sceneRouterDidChange      — fired by SceneRouter.go(...)
  └── UIApplication notifications (background, foreground, terminate)
```

No other notifications are allowed. Cross-scene communication goes
through `SceneRouter` or through direct method calls on the singleton
services.

### 6.3 File Organization

Code lives in platform-grouped folders:

```
bunny iOS/        iOS target — most code, all scenes
bunny macOS/      macOS shim (reuses iOS scenes)
bunny tvOS/       tvOS shim (reuses iOS scenes)
bunny Shared/     shared assets (AppIcon, AccentColor)
```

The scenes (`Scenes/`), UI (`UI/`), models (`Models/`), and services
(`Services/`) subfolders are added to all three targets via Xcode project
membership.

### 6.4 Asset Strategy

- **Static illustrations**: `.xcassets` asset catalogs (1x, 2x, 3x)
- **Per-scene art**: per-scene asset folder (e.g., `Bedroom.imageset`)
- **Procedural UI**: `SKShapeNode` for rings, counters, progress dots
- **Audio**: deferred to v2 (currently TTS only)
- **Levels data**: `levels.json` (ADR-0005)

---

## 7. Concurrency Model

Swift 5's structured concurrency is available but **not heavily used** in v1:

- All gameplay is single-threaded on the main actor
- `SpeechService.speak` is asynchronous but UI-bound
- File I/O (`ProgressStore`) happens synchronously on scene teardown
- Network I/O is forbidden by ADR (Pillar 4)

If v2 introduces a leaderboard or content download, it will adopt
Swift Concurrency (async/await) at that time.

---

## 8. Error Handling Strategy

- **Recoverable errors** (e.g., JSON decode failure): fall back to
  defaults, log via `os_log`, continue
- **User-facing errors** (e.g., parent gate wrong): show retry UI
- **Programmer errors** (fatal): use Swift's `preconditionFailure`
- **Never** show a generic alert to a child — every error path must have
  a kid-friendly equivalent

---

## 9. Testing Strategy

| Layer | Test type | Tools |
|---|---|---|
| Models (`Curriculum`, etc.) | Unit | XCTest |
| Services (`ProgressStore`, `SceneRouter`, `SpeechService`) | Unit | XCTest, protocol mocks |
| Scene lifecycle | Integration | XCTest + SKView rendering |
| Visual layout | Manual | Playtest scripts |
| Accessibility | Manual | VoiceOver, Dynamic Type |
| Performance | Manual | Instruments |

Test target: `bunnyTests/` (to be added to the Xcode project as a new
target — see Sprint 1 stories).

---

## 10. Build & Release

- **Build**: `xcodebuild` (per platform); `bunny iOS` / `bunny macOS` /
  `bunny tvOS` schemes
- **CI**: deferred — GitHub Actions workflow tracked as a Sprint-2 story
- **Distribution**: App Store (iOS, iPadOS, tvOS, macOS); TestFlight
  for beta
- **Versioning**: semantic (MAJOR.MINOR.PATCH); current v0.1.0

---

## 11. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| tvOS focus engine integration blocks Apple TV release | Defer tvOS launch; ship iOS / iPadOS / macOS first |
| Pre-iPhone-SE-2 devices fail performance budgets | We don't support them — minimum is iPhone SE 2 |
| String extraction becomes painful at v2 | Plan migration in v1; keep strings small |
| Lost progress from app kill | `ProgressStore.flush()` in every scene's `willMove` |
| Kids with motor difficulties can't tap precisely | 80×80 touch targets + 16pt spacing |

---

## 12. Future Architectural Work

- SwiftUI bridge for the parent dashboard (Pillar 4 — keeps iOS-native)
- Localization pipeline (Localization System GDD)
- Pre-recorded audio assets (Audio System v2)
- Animation pipeline (Spine / Lottie export)
- Telemetry-free session replay for designer review (in-app only)

Last updated: 2026-01
