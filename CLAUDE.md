# CLAUDE.md

Master configuration for the **bunny** project. Claude Code reads this file at the
start of every session. Personal overrides go in `CLAUDE.local.md` (gitignored).

---

## Project Identity

| Field | Value |
|---|---|
| **Project name** | bunny |
| **Genre** | Early-learning / Edutainment (kids ages 4–7) |
| **Protagonist** | Pip — a curious bunny |
| **Learning areas** | Math (25 levels) · English (15 levels) · Life Skills (10 levels) |
| **Total content** | 50 levels across 3 areas |
| **Codebase state** | Pre-production → Production (functional prototype, missing design docs) |
| **Primary document** | `design/gdd/` (game design documents) |
| **Working directory** | `/Users/kaiyan/Documents/bunny` |

**One-line pitch**: A gentle, parent-approved iPad-first edutainment app where Pip
guides children through 50 short, hand-directed learning scenes — Math, English,
and everyday Life Skills — each scene completing in under 90 seconds.

---

## Engine & Platform

| Field | Value |
|---|---|
| **Language** | Swift 5.0 |
| **Engine** | SpriteKit (`SKView` + `SKScene`) |
| **Build system** | Xcode 26+ / Swift Package Manager (no external deps) |
| **Asset pipeline** | Xcode asset catalogs (`.xcassets`) + JSON resources |
| **UI layer** | SpriteKit-first; UIKit only for the host `GameViewController` |
| **State management** | `SceneRouter` (singleton, notification-driven scene swaps) |
| **Persistence** | `ProgressStore` (UserDefaults-backed) |
| **Audio / Speech** | `SpeechService` (AVFoundation for TTS, bundled sound effects) |
| **Targets** | `bunny iOS` · `bunny macOS` · `bunny tvOS` |
| **Deployment target** | iOS 26.5 / macOS 26.5 / tvOS 26.5 |
| **Orientation** | iPhone/iPad portrait, iPad also portrait-upside-down; tvOS / macOS free-form |
| **Minimum device** | iPhone SE 2 / iPad (5th gen) / Apple TV HD |

## Engine Version Reference

@docs/engine-reference/spritekit/VERSION.md

> Any engine change requires updating that doc **and** an ADR in
> `docs/architecture/adr/`.

---

## Repository Layout

The project uses a **platform-grouped Xcode layout** (preserved from Apple's
default SpriteKit template). Each platform has its own scheme and target.

```
/
├── CLAUDE.md                          # This file (master config)
├── CLAUDE.local.md                    # Personal overrides (gitignored)
├── .claude/                           # Agent / skill / hook / template config
├── bunny.xcodeproj/                   # Xcode workspace (single project, 3 targets)
│
├── bunny Shared/                      # Shared assets (AppIcon, AccentColor)
│   └── Assets.xcassets/
│
├── bunny iOS/                         # iOS target (iPhone + iPad)
│   ├── App/BunnyAppDelegate.swift
│   ├── SceneDelegate.swift
│   ├── GameViewController.swift       # Hosts the SKView; routes scenes
│   ├── Scenes/                        # 14 SKScene subclasses
│   ├── UI/                            # SKTheme, SKButton, SKCard, SKHUD, SKLayout, SKBridge
│   ├── Models/                        # Curriculum, SceneRoute, EnglishActionProgress, …
│   ├── Services/                      # ProgressStore, SpeechService
│   ├── Resources/levels.json          # Authoritative curriculum data
│   ├── Assets.xcassets/               # 28 illustrations (Bedroom, MathBakery, …)
│   ├── Base.lproj/Main.storyboard
│   └── Info.plist
│
├── bunny macOS/                       # macOS target (Catalyst-style host)
│   ├── AppDelegate.swift
│   ├── GameViewController.swift       # Slim shim — reuses iOS scene code
│   └── Base.lproj/Main.storyboard
│
├── bunny tvOS/                        # tvOS target (Apple TV focus-engine)
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   ├── GameViewController.swift
│   ├── Base.lproj/Main.storyboard
│   └── Info.plist
│
├── design/                            # ← planning deliverables live here
│   ├── game-concept.md
│   ├── game-pillars.md
│   ├── systems-index.md
│   ├── gdd/                           # Per-system GDDs (math-system.md, english-system.md, …)
│   ├── narrative/                     # Character bios, world lore
│   ├── levels/                        # Per-level design notes
│   └── balance/                       # Difficulty curves, economy tuning
│
├── docs/                              # ← technical deliverables
│   ├── architecture/
│   │   ├── overview.md                # Master architecture doc
│   │   ├── control-manifest.md        # Programmer rule sheet (do / never do)
│   │   └── adr/                       # Architecture Decision Records (NNN-slug.md)
│   ├── engine-reference/spritekit/    # Version-pinned SpriteKit references
│   ├── api/                           # Generated API reference (if any)
│   └── postmortems/
│
├── production/                        # ← process artifacts
│   ├── stage.txt                      # Current development stage
│   ├── sprints/                       # Per-sprint plans (sprint-NN.md)
│   ├── milestones/                    # Milestone definitions
│   ├── releases/                      # Release notes
│   ├── epics/                         # Epic bundles (production/epics/<slug>/story-NN-*.md)
│   ├── qa/bugs/                       # Bug reports
│   ├── session-state/                 # Ephemeral (gitignored)
│   └── session-logs/                  # Audit trail (gitignored)
│
├── tests/                             # ← verification
│   ├── unit/                          # XCTest targets
│   ├── integration/                   # Scene-flow integration tests
│   └── playtest/                      # Manual playtest scripts
│
├── assets/                            # ← raw asset dumps (built outputs go into the .xcassets bundles)
│   ├── art/
│   ├── audio/
│   ├── data/
│   └── shaders/
│
├── prototypes/                        # Throwaway experiments (NEVER import into src/)
│
└── tools/                             # Build / pipeline helpers
    ├── ci/
    └── asset-pipeline/
```

> **Convention**: When a planning skill says "create `docs/architecture/adr/NNN-name.md`",
> the path is relative to this root.

---

## Working Agreements

### Code changes
- All Swift changes live in `bunny iOS/`, `bunny macOS/`, `bunny tvOS/`, or
  `bunny Shared/`. Do not move files between targets without updating the Xcode
  project membership.
- Shared scene code lives in `bunny iOS/Scenes/` and is **reused** by macOS / tvOS
  via target membership (no source duplication).
- New scenes must implement `SKScene` and be reachable through `SceneRouter`.

### Planning changes
- Every GDD section starts with a stable requirement ID (e.g. `TR-MATH-001`) that
  ADRs and stories can reference.
- ADRs are immutable once **Accepted**. A change to an Accepted ADR requires a new
  ADR that supersedes it.
- Sprints cannot include stories whose GDD section is **draft** — promote to
  **approved** first.

### Agent & skill usage
- Read `.claude/agent-coordination-map.md` before starting multi-agent work.
- Run `/project-stage-detect` whenever unsure of current stage.
- Skills listed in `.claude/docs/skills-reference.md` are the canonical workflow;
  ad-hoc scripts go in `tools/`.

### Branch & commit
- Default branch: `main`. Working branch: `feature/<epic-slug>` or `fix/<bug-id>`.
- Commit messages: `area(scope): summary` — see `coding-standards.md`.

---

## Current Stage

**Production (early)** — code is functional but lacks design / architecture docs.

See `production/stage.txt` and `production/project-stage-report.md` (when present)
for the formal assessment.

Next planned steps (in order):
1. `/setup-engine` — pin SpriteKit version, write engine-reference
2. `/adopt` — brownfield gap audit
3. `/brainstorm` + `/reverse-document concept` — `game-concept.md`
4. `/game-pillars` — `game-pillars.md`
5. `/map-systems` — `systems-index.md`
6. `/design-system` — per-system GDDs
7. `/create-architecture` + `/architecture-decision` — architecture & ADRs
8. `/create-control-manifest` — programmer rule sheet
9. `/create-epics` + `/create-stories` — implementable backlog
10. `/sprint-plan` — first sprint
