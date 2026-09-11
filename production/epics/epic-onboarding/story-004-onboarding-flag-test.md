# Story S1-04 — XCTest for Onboarding Flag

**Epic**: EPIC-001 — Onboarding & First-Run Experience
**Status**: Ready (depends on S1-03)
**GDD req**: TR-ONB-005, TR-ONB-006, TR-ONB-007
**ADR**: ADR-0003 (persistence)
**Story type**: Test
**Acceptance test**: unit test passes in CI

---

## Context

The `onboardingComplete` flag drives first-launch routing. A bug here
silently breaks onboarding. We need explicit XCTest coverage before
Sprint 1 review.

---

## Acceptance Criteria

- [ ] `tests/unit/progress-store-onboarding.test.swift` exists
- [ ] Test 1: bootstrap leaves `onboardingComplete = false` by default
- [ ] Test 2: setting `onboardingComplete = true` survives `flush()` + reload
- [ ] Test 3: `resetAllProgress()` resets `onboardingComplete` to `false`
- [ ] Test 4: corrupted `onboardingComplete` value defaults to `false`
  without crash
- [ ] All tests pass in CI

---

## Implementation Notes

- The XCTest target does not yet exist. **Adding the test target is part
  of EPIC-005 (CI & Test Setup).** For now, this story is blocked on
  EPIC-005 / S2-01.
- Tests use a `UserDefaults(suiteName: "bunny-test")` instance injected
  into `ProgressStore` to avoid clobbering real state

---

## Engine Risk

**None** — pure Swift test.

---

## Test Evidence Path

This file IS the test evidence. CI run logs show pass/fail.
