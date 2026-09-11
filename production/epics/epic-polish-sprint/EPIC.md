# EPIC-006 — Performance & Polish Sprint

**Slug**: `epic-polish-sprint`
**Status**: Ready
**Owner**: performance-analyst + technical-artist
**GDD**: `docs/engine-reference/spritekit/performance-budgets.md`
**ADR**: ADR-0001 (engine pin)
**Pillars served**: Pillar 1 (Calm)

---

## Goal

Every scene hits the documented performance budgets on the minimum
device (iPhone SE 2, iPad 5th gen, Apple TV HD). Visual polish is
consistent across all 50 levels.

---

## Scope

### In scope
- Instruments profiling of all 14 scenes
- Frame budget enforcement (10 ms typical, 16.6 ms hard cap)
- Memory ceiling enforcement (150 MB typical, 250 MB cap)
- Particle / lighting tier per scene
- Visual polish pass on all 50 level backgrounds

### Out of scope
- Apple TV focus engine (EPIC-008)
- Audio asset polish (v2)

---

## Story Catalog

| Story | Title | Status | Depends on |
|---|---|---|---|
| S6-01 | Instruments profile of all 14 scenes | Ready | EPIC-002 |
| S6-02 | Frame budget fixes (per-scene) | Ready | S6-01 |
| S6-03 | Memory ceiling fixes (per-scene) | Ready | S6-01 |
| S6-04 | Visual polish: 50 backgrounds audit | Ready | — |

---

## Acceptance Criteria

- [ ] All 14 scenes hit < 10 ms frame time on iPhone SE 2
- [ ] All 14 scenes stay < 150 MB RAM on iPhone SE 2
- [ ] Particle counts respect device tier (high / medium / low)
- [ ] All 50 backgrounds pass visual consistency review

Last updated: 2026-01
