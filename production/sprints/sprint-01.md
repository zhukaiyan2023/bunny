# Sprint 01 — Foundation, Tests, Onboarding

**Sprint window**: 2026-01-15 → 2026-01-28 (2 weeks)
**Theme**: Stabilize what exists; lay the testing foundation; ship first onboarding flow
**Velocity assumption**: 1 developer, ~50% coding / 50% review + docs
**Goal**: bunny has automated tests, a working first-launch onboarding flow, and a CI pipeline that catches regressions.

---

## Capacity

- **Story points**: 25 (single-developer, 2-week sprint)
- **Daily check-in**: not required; weekly sprint review
- **Definition of done**:
  - Code merged to `main`
  - All acceptance criteria in the story file met
  - XCTest passes
  - `control-manifest.md` rules respected
  - Pre-merge code review by `lead-programmer`

---

## Committed Stories (23 points)

### From EPIC-005 — CI & Test Infrastructure (foundation)
| ID | Story | Points | Owner |
|---|---|---|---|
| **S5-01** | GitHub Actions: build all 3 targets | 3 | devops-engineer |
| **S5-03** | `levels.json` schema validator in CI (script) | 2 | engine-programmer |
| **S5-04** | Forbidden-patterns lint (no UserDefaults outside ProgressStore, no SKView.presentScene outside GameViewController, no `#if os(...)` in scenes) | 3 | engine-programmer |

### From EPIC-002 — Persistence Hardening + Unit Tests
| ID | Story | Points | Owner |
|---|---|---|---|
| **S2-01** | Add `bunnyTests` XCTest target to Xcode project | 2 | engine-programmer |
| **S2-02** | `ProgressStore` round-trip tests | 3 | engine-programmer |
| **S2-03** | `Curriculum` JSON decode + fallback tests | 2 | engine-programmer |
| **S2-04** | `SceneRouter` route transition tests | 2 | engine-programmer |

### From EPIC-001 — Onboarding & First-Run
| ID | Story | Points | Owner |
|---|---|---|---|
| **S1-01** | WelcomeScene — first-launch greeting | 2 | gameplay-programmer |
| **S1-02** | Wire Welcome → M01 → Parent Primer → Menu | 3 | gameplay-programmer |
| **S1-03** | Reset Progress re-triggers onboarding | 1 | gameplay-programmer |

**Total committed**: 21 points

---

## Stretch Goals (2 points — pick if ahead)

| ID | Story | Points | Owner |
|---|---|---|---|
| S1-04 | XCTest for `onboardingComplete` flag | 1 | engine-programmer |
| S2-05 | Fold S2-02/S2-03/S2-04 into CI | 1 | devops-engineer |
| S7-01 | `CurriculumValidator` XCTest class skeleton | 2 | engine-programmer |

---

## Out of Sprint (parked)

These are valid work; we just don't have capacity in Sprint 1:

- **S5-02** XCTest in CI — needs S2-* done first
- **S6-01..04** Performance audit — Sprint 2
- **S3-01..05** Accessibility audit — Sprint 3
- **S4-01..04** Content authoring pipeline — Sprint 3
- **S7-02..05** Curriculum validator beyond the skeleton — Sprint 2
- **EPIC-008** tvOS focus proxy — post-launch

---

## Dependencies Between Stories

```
S2-01 (test target) ─┐
                     ├─→ S2-02 ─┐
                     ├─→ S2-03  │
                     └─→ S2-04  ├─→ (S5-02 in Sprint 2)
                                │
S5-01 (CI workflow) ────────────┤
S5-03 (schema validator) ───────┤
S5-04 (forbidden patterns) ──────┤
                                │
S1-01 (welcome scene) ──→ S1-02 (wire flow) ──→ S1-03 (reset)
```

Critical path: `S2-01 → S2-02/S2-03/S2-04 → S5-01/S5-03/S5-04 → Sprint 2 CI`

---

## Risks

| Risk | Mitigation |
|---|---|
| Test target breaks existing build | Add target last; merge smallest change first |
| Adding XCTest target requires Xcode project surgery | Use `xcodeproj` Ruby gem or hand-edit `pbxproj` carefully; pair-review |
| WelcomeScene TTS fires before scene is visible | Use `didMove(to:)` not `init(size:)` |
| Reset Progress wipes test data | Tests use isolated `UserDefaults(suiteName:)` |
| Sprint slips if any story uncovers a deeper issue | Stretch goals are first to drop |

---

## Demo at Sprint Review (end of Sprint 1)

1. **New install**: app launches into `WelcomeScene` → Pip speaks → tap → M01 → Reward → ParentPrimer → Menu
2. **Re-launch**: app goes directly to `MenuScene` (no onboarding)
3. **Reset Progress** (in parent area, double-gate): app re-runs onboarding
4. **CI**: every PR runs `xcodebuild test` for all 3 targets; forbidden-patterns lint runs
5. **Test report**: coverage report for `ProgressStore`, `Curriculum`, `SceneRouter`

---

## Sprint Review Checklist

- [ ] All committed stories complete and merged
- [ ] Sprint demo rehearsed
- [ ] Sprint retrospective notes captured in `production/sprints/sprint-01-retro.md`
- [ ] Sprint 2 backlog drafted from stretch goals + parked stories

---

Last updated: 2026-01
