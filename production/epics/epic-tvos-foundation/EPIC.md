# EPIC-008 — tvOS Foundation (Focus Proxy)

**Slug**: `epic-tvos-foundation`
**Status**: Ready (deferred to post-Sprint-1)
**Owner**: engine-programmer + ui-programmer
**GDD**: `design/gdd/platform-system.md`
**ADR**: ADR-0006 (tvOS focus proxy)
**Pillars served**: (operational)

---

## Goal

bunny scenes work on Apple TV via a `UIFocusEnvironment` proxy that
bridges Siri Remote input to in-scene node selection.

---

## Scope

### In scope
- `SKFocusProxy` UIView subclass that overlays the SKView
- Focus highlight that follows in-scene `SKSpriteNode` bounds
- Siri Remote `.select` → routes to the focused node
- D-pad navigation between focusable in-scene nodes
- Manual playtest of all 14 scenes on tvOS Simulator

### Out of scope
- Apple TV HD-specific performance tuning (covered by EPIC-006)
- tvOS App Store metadata (post-launch)

---

## Story Catalog

| Story | Title | Status | Depends on |
|---|---|---|---|
| S8-01 | `SKFocusProxy` design + spike | Ready | — |
| S8-02 | Focus highlight overlay rendering | Ready | S8-01 |
| S8-03 | D-pad navigation between focusables | Ready | S8-02 |
| S8-04 | Siri Remote `.select` → node tap | Ready | S8-03 |
| S8-05 | All 14 scenes manual playtest on tvOS | Ready | S8-04 |

---

## Acceptance Criteria

- [ ] Every scene is fully playable on Apple TV via Siri Remote
- [ ] Focus highlight is visible (cream outline, 4pt stroke)
- [ ] D-pad navigation never gets stuck
- [ ] No scene retains keyboard focus past its deallocation
- [ ] Manual playtest script covers all 14 scenes

Last updated: 2026-01
