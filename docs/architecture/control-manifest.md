# Control Manifest — bunny Programmer Rules

**Status**: Approved (v1.0)
**Last updated**: 2026-01
**Audience**: every programmer, every PR review

This is the **flat, scan-friendly rule sheet**. ADRs explain the **why**;
this file is the **what to do (and not do) today**.

---

## MUST DO

### Routing & scenes
- ✅ Navigate via `SceneRouter.shared.go(.route)` from any code
- ✅ Use `GameSceneFactory.makeScene(size:level:)` for level-driven scenes
- ✅ Follow the scene lifecycle: `init → didMove → update → touchesBegan → willMove`
- ✅ Store every notification observer's token and `removeObserver(token)`
  in `willMove(from:)`
- ✅ Call `ProgressStore.shared.flush()` in `willMove(from:)`
- ✅ Use `SKBridge.transition(to: route)` for scene transitions

### UI
- ✅ Reference `SKTheme` tokens for every color, font, padding
- ✅ Use `SKButton` for every tap target — never custom touch handlers
- ✅ Use `SKHUD` for every scene's heads-up display
- ✅ Use `SKLayout.*` helpers for placement
- ✅ Set `accessibilityLabel` on every interactive `SKNode`

### Audio
- ✅ Speak every prompt via `SpeechService.shared.speak(_:)`
- ✅ Read rate from `ProgressStore.shared.ttsRate` if no rate given
- ✅ Allow `speak(...)` to interrupt current speech

### Persistence
- ✅ Reference `ProgressStore.shared` for all read/write of game state
- ✅ Use `ProgressStore.Keys.*` constants — never string literals
- ✅ Make `ProgressStore` calls the only `UserDefaults` touchpoints

### Accessibility
- ✅ Honor `UIAccessibility.isReduceMotionEnabled` (via
  `SKBridge.applyMotionPreferences(to:)`)
- ✅ Ensure every touch target is ≥ 80 × 80 points
- ✅ Pair every color cue with a shape / label / speech cue
- ✅ Test every scene at xxxLarge Dynamic Type

### Performance
- ✅ `update(_:)` cost stays < 3 ms (hard cap)
- ✅ First frame of every scene within 200 ms of `presentScene`
- ✅ All transition durations match `SKTheme.standardTransitionDuration`
  or documented scene-specific overrides

### Curriculum & content
- ✅ Add levels via `levels.json` edits — never Swift literals
- ✅ Validate `levels.json` schema in CI

---

## MUST NEVER DO

### Routing & scenes
- ❌ Call `SKView.presentScene(...)` from anywhere except
  `GameViewController`
- ❌ Create `SKScene` instances inline in button handlers
- ❌ Use `#if os(...)` directives inside scene files
- ❌ Subscribe to `.sceneRouterDidChange` from anywhere except
  `GameViewController`
- ❌ Hold `SKScene` references in `SceneRouter`

### Persistence
- ❌ Call `UserDefaults.standard.set(...)` directly anywhere
- ❌ Read from `UserDefaults` inside `SKScene.update(_:)`
- ❌ Persist anything to iCloud, Keychain (except parent gate), network,
  or any external location
- ❌ Implement a streak / "consecutive days" mechanic

### Audio
- ❌ Play any sound at app launch without explicit user action
- ❌ Use `AVAudioSession.Category.playback` (would ignore silent switch)
- ❌ Use `.red` / `.yellow` / loud colors anywhere in the app

### Networking
- ❌ Make any network call from anywhere in the app (Pillar 4)
- ❌ Add third-party SDKs without an ADR (ADR-0007)
- ❌ Add analytics, telemetry, or tracking of any kind

### UI
- ❌ Hardcode a hex color anywhere outside `SKTheme`
- ❌ Hardcode a font name anywhere outside `SKTheme`
- ❌ Add a "game over" / "you lost" / "try again to win" message
- ❌ Add a "best time" / "personal record" / leaderboard
- ❌ Add a "share" button to any scene

### Performance
- ❌ Allocate arrays inside `update(_:)`
- ❌ Trigger texture atlas loads during gameplay
- ❌ Use `SKFieldNode` (too expensive)

### Code style
- ❌ Use `print(...)` in shipped builds (use `os_log` or `Logger`)
- ❌ Add singletons beyond the three allowed (`SceneRouter`,
  `ProgressStore`, `SpeechService`)
- ❌ Use `var` where `let` works
- ❌ Use `open class` — `final class` is default

---

## WATCH OUT FOR

### When reviewing a PR
- 👀 Any new `UserDefaults.standard` reference → reject
- 👀 Any new `SKView.presentScene` call outside `GameViewController` →
  reject
- 👀 Any new `print(...)` in a scene → reject
- 👀 Any new `#if os(...)` inside a scene file → reject
- 👀 Any new third-party SPM dependency without an ADR → reject
- 👀 Any new `NotificationCenter` subscriber without a stored observer
  token → reject
- 👀 Any new color or font outside `SKTheme` → reject
- 👀 Any new touch target < 80 × 80 → reject
- 👀 Any new "score" or "record" mechanic → reject
- 👀 Any new "streak" or "missed day" mechanic → reject
- 👀 Any new analytics SDK or telemetry hook → reject (Pillar 4)

### When extending `SceneKind`
- 👀 New scene types should reuse an existing kind if the mechanic is
  the same — only add a new case when the mechanic is genuinely new

### When touching curriculum data
- 👀 `levels.json` schema must remain valid (XCTest validates on CI)
- 👀 IDs must follow `[MEL]<NN>` pattern
- 👀 `difficulty` must be in `[1, 5]`

---

## Quick Reference — Allowed Singletons

| Singleton | File | Allowed because |
|---|---|---|
| `SceneRouter.shared` | `bunny iOS/Models/SceneRoute.swift` | Cross-cutting navigation; ADR-0002 |
| `ProgressStore.shared` | `bunny iOS/Services/ProgressStore.swift` | Cross-cutting persistence; ADR-0003 |
| `SpeechService.shared` | `bunny iOS/Services/SpeechService.swift` | Cross-cutting audio |

Any new singleton → must be justified in an ADR.

---

## Quick Reference — Allowed Notifications

| Name | Fired by | Observed by |
|---|---|---|
| `.sceneRouterDidChange` | `SceneRouter.go(_:)` | `GameViewController` only |

Any new notification → must be added to this list AND documented in the
relevant GDD.

---

## Quick Reference — Allowed Third-Party Deps

**None.**

Any addition requires ADR-0007 review.

---

## Cross-Reference

| Rule | Backed by |
|---|---|
| Routing pattern | ADR-0002, `routing-system.md` |
| Persistence layer | ADR-0003, `persistence-system.md` |
| Engine pin | ADR-0001, `docs/engine-reference/spritekit/` |
| Curriculum data | ADR-0005, `curriculum-system.md` |
| Multi-platform | ADR-0004, `platform-system.md` |
| tvOS focus | ADR-0006 |
| Zero deps | ADR-0007 |
| Pillars | `game-pillars.md` |

Last updated: 2026-01
