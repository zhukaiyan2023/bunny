# Milestone M1 — Foundation & First-Run

**Target date**: end of Sprint 3 (≈ 2026-02-26)
**Theme**: Stabilize the foundation. Ship the first vertical slice end-to-end.

---

## Definition of Done

A parent can install bunny, complete onboarding, watch their child play
M01, and see a star awarded in the parent dashboard. The build is
covered by automated tests on all three platforms. The codebase has
documentation that lets a new contributor onboard in a single afternoon.

---

## Acceptance Criteria

### Onboarding (EPIC-001)
- [ ] First launch shows Welcome → M01 → Parent Primer → Menu
- [ ] Reset Progress re-triggers onboarding

### Testing (EPIC-002)
- [ ] `bunnyTests` target builds and runs
- [ ] All `ProgressStore` keys round-trip
- [ ] `Curriculum` decode returns 50 levels; fallback works
- [ ] `SceneRouter` route transitions tested

### CI (EPIC-005)
- [ ] GitHub Actions builds all 3 targets
- [ ] GitHub Actions runs XCTest
- [ ] `levels.json` schema validator runs in CI
- [ ] Forbidden-patterns lint runs in CI

### Accessibility (EPIC-003)
- [ ] All 14 scenes pass VoiceOver manual playtest
- [ ] All touch targets ≥ 80×80
- [ ] Reduce Motion honored in every scene
- [ ] Dynamic Type at xxxLarge fits without overflow

### Content (EPIC-004)
- [ ] All 50 levels have a `design/levels/<id>.md` per-level doc
- [ ] Difficulty curve audit complete
- [ ] Designer runbook published

### Polish (EPIC-006)
- [ ] All 14 scenes hit < 10 ms frame time on iPhone SE 2
- [ ] All 14 scenes stay < 150 MB RAM on iPhone SE 2

### Validator (EPIC-007)
- [ ] `CurriculumValidator` catches every documented schema violation
- [ ] Validator runs in CI

---

## Out of Milestone Scope

- **EPIC-008 tvOS Foundation** — tvOS launch is post-M1
- **Localization** — v2
- **Telemetry / analytics** — explicitly forbidden (Pillar 4)
- **App Store submission** — pre-launch work, post-M1

---

## Sprint Breakdown

| Sprint | Window | Theme | Epics |
|---|---|---|---|
| Sprint 1 | 2026-01-15 → 2026-01-28 | Foundation + first onboarding flow | EPIC-005, EPIC-002, EPIC-001 |
| Sprint 2 | 2026-01-29 → 2026-02-11 | CI integration + curriculum validator + content | EPIC-005 (continued), EPIC-007, EPIC-004 |
| Sprint 3 | 2026-02-12 → 2026-02-26 | Accessibility + polish | EPIC-003, EPIC-006 |

---

## Go / No-Go Decision

At the end of Sprint 3, the team decides whether to:

- **GO** → move into M2 (Apple TV + Localization v2)
- **POLISH** → take another sprint to hit remaining polish items
- **HOLD** → wait for design / parenting feedback before M2

Last updated: 2026-01
