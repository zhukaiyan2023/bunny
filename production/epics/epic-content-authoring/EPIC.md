# EPIC-004 — Content Authoring Pipeline

**Slug**: `epic-content-authoring`
**Status**: Ready
**Owner**: game-designer + technical-artist
**GDD**: `design/gdd/curriculum-system.md`
**ADR**: ADR-0005 (curriculum as JSON)
**Pillars served**: Pillar 2 (Tasks)

---

## Goal

Establish a designer-friendly workflow for adding, editing, and
reviewing levels without programmer involvement.

---

## Scope

### In scope
- `levels.json` schema documented and enforced
- Per-level design doc template in `design/levels/`
- Difficulty curve analysis (current vs ideal) in `design/balance/`
- Per-area difficulty progression review
- Designer-facing "How to add a level" runbook

### Out of scope
- Visual content authoring (separate pipeline — `tools/asset-pipeline`)
- Audio recording (v2)

---

## Story Catalog

| Story | Title | Status | Depends on |
|---|---|---|---|
| S4-01 | Per-level design doc template | Ready | — |
| S4-02 | Difficulty curve audit (50 levels) | Ready | S4-01 |
| S4-03 | Per-area balance review notes | Ready | S4-02 |
| S4-04 | Designer runbook in `design/levels/README.md` | Ready | S4-01 |

---

## Acceptance Criteria

- [ ] All 50 levels have a `design/levels/M01.md` (etc.) per-level doc
- [ ] Difficulty curve fits the documented 1–5 scale per cluster
- [ ] Designer can add a new level by following the runbook alone
- [ ] No new level ships without a per-level design doc

Last updated: 2026-01
