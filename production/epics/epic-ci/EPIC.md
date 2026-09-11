# EPIC-005 — CI, Test Infrastructure, Release Pipeline

**Slug**: `epic-ci`
**Status**: Ready
**Owner**: devops-engineer
**GDD**: n/a (infrastructure)
**ADRs**: ADR-0004 (single project), ADR-0007 (zero deps)
**Pillars served**: (operational)

---

## Goal

Every PR is built and tested on three platforms (iOS, macOS, tvOS) by
GitHub Actions before merge. TestFlight builds ship automatically on
release tags.

---

## Scope

### In scope
- GitHub Actions workflow that builds all 3 targets
- XCTest runs in CI
- `levels.json` schema validation in CI
- SwiftLint (or equivalent) check
- TestFlight upload on tag push (post-launch)

### Out of scope
- App Store Connect automation (v2)
- Crash reporting (Pillar 4 forbids it — not in scope at all)

---

## Story Catalog

| Story | Title | Status | Depends on |
|---|---|---|---|
| S5-01 | GitHub Actions: build all 3 targets | Ready | — |
| S5-02 | GitHub Actions: run XCTest suite | Ready | S5-01, EPIC-002 |
| S5-03 | `levels.json` schema validator in CI | Ready | S5-01 |
| S5-04 | Forbidden-patterns lint (no UserDefaults outside ProgressStore, etc.) | Ready | S5-01 |

---

## Acceptance Criteria

- [ ] CI builds succeed for iOS, macOS, tvOS
- [ ] All XCTest tests pass in CI
- [ ] `levels.json` schema validation runs on every PR
- [ ] PR introducing a forbidden pattern fails CI

Last updated: 2026-01
