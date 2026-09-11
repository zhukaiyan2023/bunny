# EPIC-002 — Persistence Hardening + Unit Test Coverage

**Slug**: `epic-persistence-tests`
**Status**: Ready
**Owner**: engine-programmer
**GDD**: `design/gdd/persistence-system.md`
**ADR**: ADR-0003 (UserDefaults over Core Data)
**Pillars served**: Pillar 3 (Persistence), Pillar 4 (Privacy)

---

## Goal

Make `ProgressStore` and `Curriculum` provably correct via XCTest
coverage, and verify all stored data survives app kill / restart.

---

## Scope

### In scope
- XCTest target added to `bunny.xcodeproj`
- Unit tests for `ProgressStore`: round-trip of every key, reset, corruption tolerance
- Unit tests for `Curriculum`: JSON decode, fallback, query
- Unit tests for `SceneRouter`: go() / no-op semantics, back stack
- CI workflow that runs `xcodebuild test` on every PR

### Out of scope
- Scene-level integration tests (tracked in EPIC-007)
- Performance testing (tracked in EPIC-006)

---

## Story Catalog

| Story | Title | Status | Depends on |
|---|---|---|---|
| S2-01 | Add `bunnyTests` XCTest target to Xcode project | Ready | — |
| S2-02 | `ProgressStore` round-trip tests | Ready | S2-01 |
| S2-03 | `Curriculum` JSON decode + fallback tests | Ready | S2-01 |
| S2-04 | `SceneRouter` route transition tests | Ready | S2-01 |
| S2-05 | GitHub Actions CI workflow | Ready | S2-01 |

---

## Acceptance Criteria

- [ ] `bunnyTests` target builds and runs
- [ ] All `ProgressStore` keys round-trip through `flush()` + reload
- [ ] `Curriculum` decode returns 50 levels; fallback works on corrupted JSON
- [ ] `SceneRouter.go(.menu)` from `.menu` is a no-op (no notification)
- [ ] GitHub Actions runs all tests on every PR
- [ ] Test coverage report shows ≥ 70% line coverage on `Models/` and `Services/`

---

## Engine Risk

**None** — pure test infrastructure.

Last updated: 2026-01
