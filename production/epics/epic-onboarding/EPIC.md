# EPIC-001 — Onboarding & First-Run Experience

**Slug**: `epic-onboarding`
**Status**: Ready
**Owner**: gameplay-programmer + ux-designer
**GDD**: `design/gdd/onboarding-system.md`
**ADRs**: ADR-0001 (engine), ADR-0002 (routing)
**Pillars served**: Pillar 1 (Calm), Pillar 5 (Adult-gated)

---

## Goal

Turn a brand-new install into a confident 4-year-old who knows how to
play, plus a parent who knows where the parent-only controls live — in
under 5 minutes.

---

## Scope

### In scope (this epic)
- New `WelcomeScene` (greets Pip, starts M01)
- New `ParentPrimerScene` (post-M01 one-time setup primer)
- Hooks into `MenuScene` to detect first run
- `ProgressStore.onboardingComplete` flag handling
- Reset Progress re-triggers onboarding
- Welcome screen reads "Hi! I'm Pip. Want to play with me?" via TTS

### Out of scope
- Video tutorial (v2)
- Multi-language welcome (v2)
- Achievements for completing onboarding (v2)

---

## Story Catalog

| Story | Title | Status | Depends on |
|---|---|---|---|
| S1-01 | WelcomeScene — first-launch greeting | Ready | — |
| S1-02 | Wire WelcomeScene → M01 → ParentPrimer → Menu | Ready | S1-01 |
| S1-03 | Reset Progress re-triggers onboarding | Ready | S1-02 |
| S1-04 | XCTest for `onboardingComplete` flag | Ready | S1-03 |

(See individual `story-NN-*.md` files in this folder.)

---

## Acceptance Criteria

- [ ] First launch shows Welcome → M01 → Parent Primer → Menu
- [ ] Subsequent launches go directly to Menu
- [ ] Reset Progress (behind parent gate × 2) clears the onboarding flag
- [ ] Welcome screen speaks the greeting within 500 ms
- [ ] No regressions in existing scene navigation
- [ ] 100% unit test coverage on `ProgressStore.bootstrap()` related to onboarding

---

## Engine Risk

**Low** — adding two new `SKScene` subclasses follows the established
pattern (see `design/gdd/scene-system.md`). No engine API changes.

---

## Untraced Requirements

None — all onboarding requirements are captured in `onboarding-system.md`.

Last updated: 2026-01
