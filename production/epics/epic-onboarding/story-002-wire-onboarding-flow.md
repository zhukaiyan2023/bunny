# Story S1-02 — Wire Welcome → M01 → Parent Primer → Menu

**Epic**: EPIC-001 — Onboarding & First-Run Experience
**Status**: Ready (depends on S1-01)
**GDD req**: TR-ONB-002, TR-ONB-003
**ADR**: ADR-0002
**Story type**: Feature
**Acceptance test**: integration + manual playtest

---

## Context

S1-01 introduces `WelcomeScene` and routes the user to M01. But after
M01 completes, the user lands on the `RewardScene` (correct) and then
needs to be routed to a new `ParentPrimerScene` (not yet built) before
finally returning to `MenuScene`. This story wires the full flow.

---

## Acceptance Criteria

- [ ] After M01's `RewardScene`, user is routed to `.parentPrimer` (new route)
- [ ] `ParentPrimerScene.swift` exists; shows 3 short text cards:
  1. How to find the parent area
  2. How to adjust TTS rate
  3. How to set the daily limit
- [ ] `ParentPrimerScene` has two buttons: "Show me" and "Later"
- [ ] "Show me" routes to `.parentGate` (then `.parentDashboard`)
- [ ] "Later" routes to `.menu` and sets `ProgressStore.onboardingComplete = true`
- [ ] Returning from `.parentDashboard` after "Show me" routes to `.menu`
  and sets `ProgressStore.onboardingComplete = true`
- [ ] `SceneRouter.back()` from `.parentPrimer` returns to `.menu` (no escape
  loop)

---

## Implementation Notes

- Add `Route.welcome` and `Route.parentPrimer` to `SceneRouter.Route`
- Add `WelcomeScene` and `ParentPrimerScene` to all 3 targets
- `ParentPrimerScene` is a `SKCard` with 3 scrollable sections
- "Show me" sets `onboardingComplete = true` after parent gate success

---

## Engine Risk

**Low** — no engine API changes.

---

## Test Evidence Path

`tests/integration/onboarding-flow.test.swift` — verifies the full route
chain `welcome → scene(M01) → reward(M01) → parentPrimer → menu`.

`tests/unit/progress-store-onboarding.test.swift` — verifies the flag
is set after the flow completes.
