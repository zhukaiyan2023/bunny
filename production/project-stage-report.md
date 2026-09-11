# Project Stage Analysis — bunny

**Date**: 2026-01
**Stage**: Production (early)
**Stage Confidence**: PASS — clearly detected

---

## Executive Summary

"bunny" is a Swift + SpriteKit edutainment app for children ages 4–7. The
codebase is **functional**: 36 Swift files, 14 scenes, a working routing
system, a `ProgressStore`, and a `SpeechService`. There are 50 levels defined
across Math (25), English (15), and Life Skills (10) areas.

What is missing is **everything that turns code into a shippable product**:
design documents, architecture decisions, control manifests, ADRs, a backlog,
and a sprint plan. The developer has implemented the *what* (50 scenes) but
not yet authored the *why*, *how*, *what-not*, and *when*.

This re-plan establishes the full planning surface so that future work can
proceed against a clear spec.

---

## Completeness Overview

| Domain | % Complete | Detail | Gap |
|---|---|---|---|
| **Design** | 0% | 0 docs | No `game-concept.md`, no `game-pillars.md`, no `systems-index.md`, no `gdd/` files, no `narrative/`, no `levels/`, no `balance/` |
| **Code** | 60% | 36 Swift files, 14 scenes | Functional but lacks comments, lacks tests, lacks ADRs backing the architecture |
| **Architecture** | 0% | 0 ADRs | No `overview.md`, no `control-manifest.md`, no `adr/` files |
| **Engine Reference** | 70% | 5 docs (just created) | Missing: code-level API examples, advanced SpriteKit gotchas |
| **Production** | 5% | `stage.txt` only | No sprint plans, no epics, no stories, no milestones, no bug reports |
| **Tests** | 0% | Empty dirs | No XCTest targets, no smoke tests, no playtest scripts |
| **Assets** | 30% | 28 illustrations in 1 catalog | No audio assets (SpeechService uses TTS), no level-specific art, no animation assets |
| **CI / Tooling** | 0% | Empty dirs | No `.github/workflows`, no SPM `Package.swift`, no `tools/` content |

---

## Codebase Inventory

### Scenes (14)
| Scene | File | Status |
|---|---|---|
| `MenuScene` | `bunny iOS/Scenes/MenuScene.swift` | ✅ exists |
| `AreaScene` | `bunny iOS/Scenes/AreaScene.swift` | ✅ exists (per-area hub) |
| `LevelMapScene` | `bunny iOS/Scenes/LevelMapScene.swift` | ✅ exists |
| `LessonPlanScene` | `bunny iOS/Scenes/LessonPlanScene.swift` | ✅ exists |
| `GameSceneFactory` | `bunny iOS/Scenes/GameSceneFactory.swift` | ✅ exists |
| `MathGameScene` | `bunny iOS/Scenes/MathGameScene.swift` | ✅ exists |
| `EnglishGameScene` | `bunny iOS/Scenes/EnglishGameScene.swift` | ✅ exists |
| `LifeSkillsGameScene` | `bunny iOS/Scenes/LifeSkillsGameScene.swift` | ✅ exists |
| `ImmersiveMissionScene` | `bunny iOS/Scenes/ImmersiveMissionScene.swift` | ✅ exists |
| `RewardScene` | `bunny iOS/Scenes/RewardScene.swift` | ✅ exists |
| `AchievementsScene` | `bunny iOS/Scenes/AchievementsScene.swift` | ✅ exists |
| `ParentGateScene` | `bunny iOS/Scenes/ParentGateScene.swift` | ✅ exists |
| `ParentDashboardScene` | `bunny iOS/Scenes/ParentDashboardScene.swift` | ✅ exists |
| *(missing: SettingsScene)* | — | ❌ TODO (settings not yet a scene) |

### UI Components (6)
`SKTheme`, `SKButton`, `SKCard`, `SKHUD`, `SKLayout`, `SKBridge` — all exist.

### Models (6)
`Curriculum`, `SceneRoute`, `EnglishActionProgress`, `SceneLessonPlan`,
`EnglishSceneAction`, `HomeMissionSpec`.

### Services (2)
`ProgressStore` (UserDefaults), `SpeechService` (TTS).

### Curriculum (`levels.json`)
50 levels authored across 3 areas.

### Platform Targets
- `bunny iOS`: full source tree
- `bunny macOS`: thin shim (`AppDelegate`, `GameViewController`, storyboard)
- `bunny tvOS`: thin shim (`AppDelegate`, `SceneDelegate`, `GameViewController`, storyboard, Info.plist)
- `bunny Shared`: AppIcon + AccentColor

---

## Gaps Identified

### Critical (must close before sprint planning)

1. **No `game-concept.md`** — there's no formal one-pager that explains what
   bunny IS, who it's FOR, what success looks like. Without it, design
   decisions are arbitrary.

2. **No `game-pillars.md`** — without pillars, every future change risks
   "pillar drift". Pillars anchor trade-off discussions.

3. **No `systems-index.md`** — without it, GDDs will be authored redundantly
   or with overlapping scope. Need a decomposition first.

4. **No GDDs** — the per-system design specs that turn gameplay intent into
   implementable requirements. Math, English, Life Skills, Progression,
   Reward, Audio, Accessibility, Parent each need their own GDD.

5. **No `architecture/overview.md`** — there's no document that explains the
   SpriteKit scene-graph architecture, the routing pattern, or the platform
   target strategy. Future contributors will rebuild this knowledge.

6. **No ADRs** — major decisions (single SKView vs multi-window, target iOS
   26.5, no third-party deps, etc.) are implicit in the code. If any decision
   needs to be revisited, there's no rationale to consult.

7. **No `control-manifest.md`** — programmers need a flat, scan-friendly rule
   sheet ("do X, never Y, watch out for Z"). The ADRs explain *why*; the
   control manifest is the *what to do today*.

### Important (needed before production)

8. **No epics** — without epic decomposition, sprint planning will lump
   unrelated work together.

9. **No stories** — without stories, there's no unit of work for the dev
   workflow (`/dev-story`, `/code-review`, `/story-done`).

10. **No sprint plan** — without a plan, the team has no shared commitment.

11. **No tests** — `ProgressStore` and `SceneRouter` are pure logic and
    easily testable; nothing tested today.

### Nice-to-have (post-first-sprint)

12. **No `levels/` per-level design notes** — only the JSON exists. Useful
    for designers to iterate on individual levels without touching code.

13. **No `balance/` difficulty curves** — needed to tune progression.

14. **No audio assets** — SpeecService uses TTS only. Pre-recorded words and
    effects would significantly improve quality.

15. **No animation assets** — SpriteKit transforms only. Spine/Lottie export
    pipeline not set up.

16. **No telemetry** — no way to know which levels kids replay, abandon, or
    skip. Privacy-preserving analytics is a future work item.

17. **No localization** — copy is hardcoded English. Spanish, French,
    Mandarin are obvious next locales.

18. **No App Store metadata** — title, description, screenshots, age rating,
    privacy policy.

---

## Recommended Next Steps

In priority order:

1. ✅ **(DONE)** Create goal, directory skeleton, `CLAUDE.md`
2. ✅ **(DONE)** Run `setup-engine` — pin SpriteKit, write engine-reference,
   update `technical-preferences.md`
3. ✅ **(DONE)** Author this stage report
4. 🟢 **Author `game-concept.md`** — formalize the vision in 2 pages
5. 🟢 **Author `game-pillars.md`** — 3–5 pillars
6. 🟢 **Run `/map-systems`** — produce `systems-index.md` with all systems
7. 🟢 **Author the 8–12 core GDDs** (in dependency order):
   - `progression-system.md` (foundation)
   - `scene-system.md` (foundation)
   - `math-system.md`
   - `english-system.md`
   - `life-skills-system.md`
   - `audio-system.md`
   - `reward-system.md`
   - `parent-system.md`
   - `accessibility-system.md` (often comes via the accessibility skill)
   - `settings-system.md` (HUD, TTS toggle, motion toggle)
8. 🟢 **Author `architecture/overview.md`** — system map, dependencies, platform notes
9. 🟢 **Author 5–7 ADRs** (ADR-0001 engine pin, 0002 routing pattern, 0003
   persistence, 0004 multi-platform, 0005 curriculum as JSON, 0006 tvOS focus,
   0007 no-third-party-deps)
10. 🟢 **Author `control-manifest.md`** — programmer rule sheet
11. 🟢 **Run `/create-epics`** — 1 epic per system
12. 🟢 **Run `/create-stories` per epic** — first cut of stories
13. 🟢 **Author `sprint-01.md`** — first sprint

---

## Sign-Off

This report is the baseline for the re-plan. Future `/project-stage-detect`
runs should show progress against the gaps listed above.

Last updated: 2026-01
