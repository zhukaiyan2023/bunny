# EPIC-007 — Curriculum Validator

**Slug**: `epic-curriculum-validator`
**Status**: Ready
**Owner**: engine-programmer + game-designer
**GDD**: `design/gdd/curriculum-system.md`
**ADR**: ADR-0005 (curriculum as JSON)
**Pillars served**: Pillar 2 (Tasks)

---

## Goal

`levels.json` is provably correct: every level validates against the
documented schema, every level is reachable, and no level is duplicated.

---

## Scope

### In scope
- XCTest that loads `levels.json` and validates every entry
- Schema checks: id pattern, difficulty range, non-empty vocabulary, …
- Cross-reference checks: every `scene` is a valid `SceneKind`
- Reachability check: every level is reachable from the area hub
- No-duplicates check: every id is unique

### Out of scope
- Designer-time lint (deferred to v2)

---

## Story Catalog

| Story | Title | Status | Depends on |
|---|---|---|---|
| S7-01 | `CurriculumValidator` XCTest class | Ready | EPIC-002 |
| S7-02 | Schema validation (id pattern, difficulty range) | Ready | S7-01 |
| S7-03 | Cross-reference validation (scene kinds) | Ready | S7-01 |
| S7-04 | Reachability validation | Ready | S7-01 |
| S7-05 | Wire validator into CI | Ready | EPIC-005 |

---

## Acceptance Criteria

- [ ] Validator catches every documented schema violation
- [ ] Validator catches every cross-reference violation
- [ ] Validator runs in CI and fails the build on errors
- [ ] 100% pass rate on the current `levels.json`

Last updated: 2026-01
