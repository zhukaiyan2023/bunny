# Systems Index — bunny

**Status**: Approved (v1.0)
**Last updated**: 2026-01

This index decomposes bunny into **16 systems**. Each system has a stable
slug, a single-sentence purpose, the GDD that documents it in full, and
the source files that implement it today.

---

## Reading order

Systems are grouped by **layer**, top-down:

| Layer | Systems |
|---|---|
| **Foundation** | Platform · Persistence · Localization · Accessibility |
| **Content** | Curriculum |
| **Experience** | Scene · Routing · UI · Audio |
| **Gameplay** | Math · English · Life Skills · Reward · Progression |
| **Player Services** | Onboarding · Parent |

When in doubt about cross-system boundaries, **lower layer systems depend
on upper layer systems, never the reverse**.

---

## Foundation Layer

### SYS-FOUND-001 — Platform System
- **Purpose**: Abstract iOS / macOS / tvOS differences (input, focus, orientation, frame lifecycle) behind a single host `GameViewController` per target.
- **GDD**: `design/gdd/platform-system.md`
- **Source**: `bunny iOS/GameViewController.swift`, `bunny macOS/GameViewController.swift`, `bunny tvOS/GameViewController.swift`, `bunny iOS/SceneDelegate.swift`, `bunny iOS/App/BunnyAppDelegate.swift`
- **ADRs**: ADR-0004 (multi-platform strategy)

### SYS-FOUND-002 — Persistence System
- **Purpose**: Read/write all local game state via a single typed wrapper around `UserDefaults`.
- **GDD**: `design/gdd/persistence-system.md`
- **Source**: `bunny iOS/Services/ProgressStore.swift`
- **ADRs**: ADR-0003 (UserDefaults over Core Data)

### SYS-FOUND-003 — Localization System
- **Purpose**: Isolate all user-facing strings behind a lookup key (placeholder for v1; full i18n in v2).
- **GDD**: `design/gdd/localization-system.md` (lightweight, deferred)
- **Source**: hardcoded strings throughout (v1); to be extracted in v2
- **ADRs**: none

### SYS-FOUND-004 — Accessibility System
- **Purpose**: Ensure every scene supports VoiceOver, Dynamic Type, Reduce Motion, Reduce Transparency, and color independence.
- **GDD**: `design/gdd/accessibility-system.md`
- **Source**: cross-cutting; `SKTheme` honors Dynamic Type; `SKBridge` exposes motion preferences
- **ADRs**: none

---

## Content Layer

### SYS-CONT-001 — Curriculum System
- **Purpose**: Author, load, query, and validate the 50-level content catalog (`levels.json`).
- **GDD**: `design/gdd/curriculum-system.md`
- **Source**: `bunny iOS/Models/Curriculum.swift`, `bunny iOS/Resources/levels.json`
- **ADRs**: ADR-0005 (curriculum as JSON data)

---

## Experience Layer

### SYS-EXP-001 — Scene System
- **Purpose**: Define the standard `SKScene` lifecycle (init → didMove → update → touchesBegan → willMove) and the scene factory pattern.
- **GDD**: `design/gdd/scene-system.md`
- **Source**: all 14 files in `bunny iOS/Scenes/`
- **ADRs**: ADR-0002 (scene routing pattern)

### SYS-EXP-002 — Routing System
- **Purpose**: Provide a singleton route enum + notification-driven scene swaps, decoupled from any scene's internal state.
- **GDD**: `design/gdd/routing-system.md`
- **Source**: `bunny iOS/Models/SceneRoute.swift`, `bunny iOS/GameViewController.swift`
- **ADRs**: ADR-0002

### SYS-EXP-003 — UI System
- **Purpose**: Provide themed UI primitives (`SKTheme`, `SKButton`, `SKCard`, `SKHUD`, `SKLayout`, `SKBridge`) so every scene looks and behaves consistently.
- **GDD**: `design/gdd/ui-system.md`
- **Source**: `bunny iOS/UI/*.swift`
- **ADRs**: none

### SYS-EXP-004 — Audio System
- **Purpose**: Provide spoken-word narration (TTS), ambient SFX, and audio ducking through a single service.
- **GDD**: `design/gdd/audio-system.md`
- **Source**: `bunny iOS/Services/SpeechService.swift`
- **ADRs**: none

---

## Gameplay Layer

### SYS-GP-001 — Math System
- **Purpose**: Author and run the 25 math scenes (counting, addition, subtraction, patterns, time, money, measurement).
- **GDD**: `design/gdd/math-system.md`
- **Source**: `bunny iOS/Scenes/MathGameScene.swift`, `bunny iOS/Scenes/GameSceneFactory.swift`
- **ADRs**: none

### SYS-GP-002 — English System
- **Purpose**: Author and run the 15 English / vocabulary scenes (object naming, action words, sequencing).
- **GDD**: `design/gdd/english-system.md`
- **Source**: `bunny iOS/Scenes/EnglishGameScene.swift`, `bunny iOS/Models/EnglishActionProgress.swift`, `bunny iOS/Models/EnglishSceneAction.swift`, `bunny iOS/Models/SceneLessonPlan.swift`
- **ADRs**: none

### SYS-GP-003 — Life Skills System
- **Purpose**: Author and run the 10 life-skills scenes (daily routines, household tasks, outdoor safety).
- **GDD**: `design/gdd/life-skills-system.md`
- **Source**: `bunny iOS/Scenes/LifeSkillsGameScene.swift`, `bunny iOS/Models/HomeMissionSpec.swift`, `bunny iOS/Scenes/ImmersiveMissionScene.swift`
- **ADRs**: none

### SYS-GP-004 — Reward System
- **Purpose**: Award 1–3 stars for completing a scene; present the celebration screen; never penalize retry.
- **GDD**: `design/gdd/reward-system.md`
- **Source**: `bunny iOS/Scenes/RewardScene.swift`
- **ADRs**: none

### SYS-GP-005 — Progression System
- **Purpose**: Track unlocked levels, achievements, daily streaks (gentle, no penalty).
- **GDD**: `design/gdd/progression-system.md`
- **Source**: `bunny iOS/Services/ProgressStore.swift`, `bunny iOS/Scenes/AchievementsScene.swift`
- **ADRs**: none

---

## Player Services Layer

### SYS-PLAYER-001 — Onboarding System
- **Purpose**: Walk a new player (and parent) through the first 3 scenes and a settings primer.
- **GDD**: `design/gdd/onboarding-system.md`
- **Source**: implicit in `MenuScene.swift`; explicit onboarding flow to be authored
- **ADRs**: none

### SYS-PLAYER-002 — Parent System
- **Purpose**: Provide a parent-only area behind a multiplication gate: progress dashboard, session cap, settings, reset progress.
- **GDD**: `design/gdd/parent-system.md`
- **Source**: `bunny iOS/Scenes/ParentGateScene.swift`, `bunny iOS/Scenes/ParentDashboardScene.swift`
- **ADRs**: none

---

## Cross-Cutting Concerns

### Compliance
- **COPPA**: No data leaves the device. Privacy policy in App Store listing.
- **App Store age rating**: 4+ (no objectionable content).
- **Guided Access**: Recommended in onboarding for parents.

### Telemetry
- **None**. Pillar 4 explicitly forbids tracking. No instrumentation hooks.

### Performance
- Frame budget and device tiers documented in `docs/engine-reference/spritekit/performance-budgets.md`.

---

## System Dependency Graph

```
Platform ──► Scene ──► Routing ──► all gameplay scenes
   │           │           │
   ▼           ▼           ▼
Persistence ──► Progression ──► Reward
   │               │              │
   ▼               ▼              ▼
Curriculum ──► Math / English / Life Skills
                   │              │
                   └──── UI ──────┘
                          │
                          ▼
                       Audio / Accessibility

Parent ──► Onboarding ──► Menu
```

---

## Coverage Map

For each of the 50 levels in `levels.json`, the gameplay layer that owns it:

| Levels | Count | Owner system |
|---|---|---|
| M01–M25 | 25 | Math System |
| E01–E15 | 15 | English System |
| L01–L10 | 10 | Life Skills System |

For each scene in `bunny iOS/Scenes/`:

| Scene | Owner system | Status |
|---|---|---|
| `MenuScene` | Onboarding | functional, polish needed |
| `AreaScene` | Routing / Onboarding | functional |
| `LevelMapScene` | Routing / Curriculum | functional |
| `LessonPlanScene` | Curriculum | functional |
| `MathGameScene` | Math | functional, scene variety limited |
| `EnglishGameScene` | English | functional |
| `LifeSkillsGameScene` | Life Skills | functional |
| `ImmersiveMissionScene` | Life Skills | functional |
| `RewardScene` | Reward | functional |
| `AchievementsScene` | Progression | functional |
| `ParentGateScene` | Parent | functional |
| `ParentDashboardScene` | Parent | functional |

---

## When to Update This Index

- A new system is added → append row, update dependency graph
- A system is split into two → update row + dependency graph
- A scene is added or removed → update coverage map
- A new ADR closes a system boundary question → link it

Last updated: 2026-01
