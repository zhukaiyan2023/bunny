# Story S1-03 — Reset Progress Re-Triggers Onboarding

**Epic**: EPIC-001 — Onboarding & First-Run Experience
**Status**: Ready (depends on S1-02)
**GDD req**: TR-ONB-007
**ADR**: ADR-0003 (persistence)
**Story type**: Feature
**Acceptance test**: integration + manual playtest

---

## Context

If a parent hands the device to another child (or another family
member), they will likely use the "Reset Progress" button in
`ParentDashboardScene`. After reset, the next launch should re-run the
onboarding flow so the new child is greeted by Pip.

---

## Acceptance Criteria

- [ ] `ProgressStore.resetAllProgress()` clears `onboardingComplete`
  along with stars, achievements, session count, etc.
- [ ] After reset, next app launch routes to `.welcome`
- [ ] Reset Progress still requires double parent gate (existing
  behavior unchanged)
- [ ] XCTest verifies `resetAllProgress()` returns `onboardingComplete`
  to its default value (`false`)

---

## Implementation Notes

- `ProgressStore.resetAllProgress()` already exists; just add
  `keys.onboardingComplete = false` to its reset block

---

## Engine Risk

**None** — pure data layer.

---

## Test Evidence Path

`tests/unit/progress-store-reset.test.swift` — verifies all keys reset,
including `onboardingComplete`.
