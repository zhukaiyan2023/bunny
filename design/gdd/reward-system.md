# Reward System — GDD

**System slug**: SYS-GP-004
**Status**: Approved (v1.0)
**Pillars served**: Pillar 2 (Tasks), Pillar 3 (Persistence)
**Last updated**: 2026-01

---

## Overview

The Reward System celebrates the completion of a scene with a brief,
calm, and **never punitive** feedback screen. It awards 1–3 stars and
routes the child back to the level map.

This system is **not a scoreboard**. It is a quiet "well done" moment.

---

## Requirements

| ID | Requirement |
|---|---|
| **TR-REW-001** | Every completed scene MUST transition to `RewardScene`. |
| **TR-REW-002** | Star count MUST be 1–3, based on (a) completion, (b) optional accuracy / time bonus. |
| **TR-REW-003** | Replaying a scene MUST NOT decrease the stored star count (max wins). |
| **TR-REW-004** | The reward screen MUST NEVER show "best time", "personal record", or any metric that frames completion as a competition. |
| **TR-REW-005** | The reward screen MUST include exactly TWO buttons: "Next" and "Map". No "Replay", no "Share". |
| **TR-REW-006** | Transitions into and out of the reward screen MUST use cross-fade (no zoom, no slide). |
| **TR-REW-007** | Audio feedback MUST be a soft chime — no fanfare, no applause, no "ding!". |
| **TR-REW-008** | Pip MUST speak one short celebratory phrase: "Great job!" / "Wonderful!" / "Hooray for Pip!" (random per scene). |

---

## Star Award Logic

| Stars | Condition |
|---|---|
| 1 ⭐ | Scene completed (touched at least one correct interaction) |
| 2 ⭐⭐ | Scene completed AND ≥ 80% of interactions correct on first try |
| 3 ⭐⭐⭐ | Scene completed AND 100% of interactions correct on first try |

"No first-try penalty" — if the child gets an answer wrong, Pip says "Good
try! Let's try again." The scene does not end early, the child gets
unlimited retries within the scene. The star count only depends on **how
many tries were needed**.

---

## Visual Design

```
┌──────────────────────────────────────────┐
│                                            │
│              🐰  (Pip, smiling)             │
│                                            │
│              "Great job!"                  │
│                                            │
│         ⭐  ⭐  ⭐   (filled or empty)      │
│                                            │
│       "Bakery Box Rescue"                  │
│                                            │
│   [ Next ]                  [ Map ]        │
└──────────────────────────────────────────┘
```

- Background: solid `SKTheme.cream`
- Stars: `SKSpriteNode` with simple yellow circles (no shading)
- Pip: small bouncing animation (300ms ease-in-out, 2 reps)
- No particles, no confetti, no flashing

---

## Anti-Patterns

| Pattern | Why wrong |
|---|---|
| Showing a "best run" or "previous attempt" | Implies competition |
| Adding a "replay" button | Encourages perfectionism |
| Sharing buttons | Privacy violation (Pillar 4) |
| Loud fanfare | Violates Pillar 1 (Calm) |
| Confetti particles | Violates Pillar 1 (Calm) |
| "You got X out of Y!" framing | Frames completion as a score |

---

## Source

- `bunny iOS/Scenes/RewardScene.swift`

---

## Acceptance Criteria

- [ ] Every scene transition into `RewardScene` succeeds (no crash)
- [ ] Replaying a 3-star scene never reduces the stored star count
- [ ] Replaying a 1-star scene after a 1st-try improvement updates to 3 stars
- [ ] The reward screen has no more than 2 buttons (verified by code review)
- [ ] No analytics event fires from `RewardScene`

---

## Open Questions

None.

Last updated: 2026-01
