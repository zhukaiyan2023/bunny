# Parent System — GDD

**System slug**: SYS-PLAYER-002
**Status**: Approved (v1.0)
**Pillars served**: Pillar 4 (Privacy), Pillar 5 (Adult-gated)
**Last updated**: 2026-01

---

## Overview

The Parent System is the **adult-only portion** of bunny. It is reachable
only through `ParentGateScene` (a single-digit × single-digit
multiplication puzzle). It exposes:

- **Parent Dashboard** — what the child practiced, when, for how long
- **Settings** — TTS rate, motion toggle, daily session cap, reset progress
- **Privacy statement** — short, in-app, written for parents

---

## Requirements

| ID | Requirement |
|---|---|
| **TR-PAR-001** | The Parent area MUST be reachable only via `ParentGateScene`. |
| **TR-PAR-002** | The parent gate MUST present a multiplication problem with operands 2–9. |
| **TR-PAR-003** | After 3 wrong attempts within 60 seconds, the gate MUST cool down for 5 minutes. |
| **TR-PAR-004** | "Reset Progress" MUST require the gate to be passed twice in succession. |
| **TR-PAR-005** | The Parent Dashboard MUST show: stars per area, last-played date, session count, total time played (approx). |
| **TR-PAR-006** | The Parent Dashboard MUST NOT show: which specific interactions were wrong, which words were mispronounced, time-per-scene. |
| **TR-PAR-007** | Settings MUST persist immediately to `ProgressStore`. |
| **TR-PAR-008** | Daily session cap MUST trigger a soft chime + Pip saying "Let's play again tomorrow!" — never a hard lock. |

---

## Parent Gate

```
┌──────────────────────────────────────────┐
│                                            │
│         Parents only!                      │
│                                            │
│   How much is 7 × 8?                      │
│                                            │
│   [ 56 ]   [ 54 ]   [ 58 ]   [ 64 ]        │
│                                            │
│   2 attempts remaining                    │
└──────────────────────────────────────────┘
```

- 4 multiple-choice options
- 2 fresh random operands per attempt (no repeats within 60s)
- 3 wrong attempts → 5-minute cooldown (`ProgressStore.parentGateFailCount`)
- Cooldown message: "Take a break! Try again in 5 minutes."

---

## Parent Dashboard

```
┌──────────────────────────────────────────┐
│  Parent Dashboard                         │
│                                            │
│  Math                                     │
│    ⭐⭐⭐  12 / 25 levels (with ≥1 star)    │
│                                            │
│  English                                  │
│    ⭐⭐    6 / 15 levels                   │
│                                            │
│  Life Skills                              │
│    ⭐⭐⭐  10 / 10 levels                  │
│                                            │
│  Last played: today                       │
│  Total sessions: 27                       │
│                                            │
│  [ Settings ]   [ Reset Progress ]   [Done]│
└──────────────────────────────────────────┘
```

---

## Settings

| Setting | Range | Default | Effect |
|---|---|---|---|
| TTS rate | 0.3 (slow) – 0.7 (fast) | 0.45 | SpeechService rate |
| Reduce motion | on / off | (system default) | Honored if on |
| Daily session cap | 5 / 10 / 15 / 20 / 30 min | 15 | Triggers soft chime + prompt |
| Reset progress | confirmation × 2 | n/a | Wipes ProgressStore keys |
| Privacy statement | (read-only) | — | Shown as text card |

---

## Source

- `bunny iOS/Scenes/ParentGateScene.swift`
- `bunny iOS/Scenes/ParentDashboardScene.swift`

---

## Anti-Patterns

| Pattern | Why wrong |
|---|---|
| Linking to the App Store from the parent area | Pressure to upgrade |
| Showing per-level error rates | Surveillance of child |
| Adding a "send feedback" email | Collects data, violates Pillar 4 |
| Social features | Privacy violation |
| Analytics in the parent area | Privacy violation |

---

## Acceptance Criteria

- [ ] Entering the parent area requires solving the gate
- [ ] Wrong-answer cooldown triggers after 3 misses
- [ ] Reset progress requires two gate passes
- [ ] Dashboard shows only the 3 aggregate metrics (not per-level errors)
- [ ] Settings persist across app restarts
- [ ] Daily session cap triggers within 30 seconds of crossing the threshold

---

## Open Questions

- Should we add per-area time limits (e.g., cap Math at 5 min/day)?
  Currently it's a single total cap.

Last updated: 2026-01
