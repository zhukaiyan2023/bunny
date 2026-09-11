# EPIC-003 — Accessibility Compliance Pass

**Slug**: `epic-accessibility`
**Status**: Ready
**Owner**: accessibility-specialist + ui-programmer
**GDD**: `design/gdd/accessibility-system.md`
**ADRs**: ADR-0001, ADR-0002
**Pillars served**: Pillar 1 (Calm), Pillar 5 (Adult-gated)

---

## Goal

Every scene in bunny is fully usable by:
- VoiceOver users
- Users with Dynamic Type set to xxxLarge
- Users with Reduce Motion enabled
- Users with Reduce Transparency enabled
- Color-blind users (grayscale palette)

---

## Scope

### In scope
- Audit all 14 scenes for missing `accessibilityLabel`
- Audit all touch targets; pad to 80×80 minimum
- Verify Reduce Motion honored in every scene
- Verify Dynamic Type at xxxLarge fits without overflow
- Add a "high contrast" theme variant (stretch)
- Per-scene accessibility review checklist filled in

### Out of scope
- Voice control (Apple's built-in Voice Control is sufficient)
- Switch Control (v2)

---

## Story Catalog

| Story | Title | Status | Depends on |
|---|---|---|---|
| S3-01 | Audit existing scenes for accessibility gaps | Ready | — |
| S3-02 | Pad all touch targets to 80×80 | Ready | S3-01 |
| S3-03 | Add Reduce Motion handling to all scenes | Ready | S3-01 |
| S3-04 | Dynamic Type overflow audit + fixes | Ready | S3-01 |
| S3-05 | Per-scene accessibility checklist | Ready | S3-04 |

---

## Acceptance Criteria

- [ ] All 14 scenes pass VoiceOver manual playtest
- [ ] All touch targets ≥ 80×80 (verified by automated check)
- [ ] All scenes render cleanly at xxxLarge Dynamic Type
- [ ] Reduce Motion triggers in every scene when enabled
- [ ] Per-scene accessibility checklist exists for every scene

Last updated: 2026-01
