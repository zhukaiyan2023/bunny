# Progression System — GDD

**System slug**: SYS-GP-005
**Status**: Approved (v1.0)
**Pillars served**: Pillar 3 (Persistence — never lose progress)
**Last updated**: 2026-01

---

## Overview

The Progression System tracks every "I did a thing" the child has done:
stars per level, unlocked levels, earned achievements, and gentle session
counters. It reads from and writes to `ProgressStore` and exposes a
read-only API to UI components.

**No streak punishment. No leaderboards. No XP bars.**

---

## Requirements

| ID | Requirement |
|---|---|
| **TR-PROG-001** | The system MUST track stars (0–3) per level id (`[String: Int]`). |
| **TR-PROG-002** | The system MUST auto-unlock the next level when a level is first completed (≥ 1 star). |
| **TR-PROG-003** | The system MUST track earned achievements as a `Set<String>`. |
| **TR-PROG-004** | The system MUST track total session count and last-played date for "X days since first play" achievements. |
| **TR-PROG-005** | Stars MUST be stored as the **maximum** ever earned — replaying cannot reduce them. |
| **TR-PROG-006** | The system MUST NOT impose a "streak" mechanic (consecutive days). Coming back after a break is always good. |
| **TR-PROG-007** | The system MUST NOT award XP, currency, or any in-app tradable resource. |

---

## Achievements (v1)

| ID | Trigger | Display name |
|---|---|---|
| `ach.first_scene` | First scene completed (any star) | "First Steps" |
| `ach.math_counting_done` | All M01–M05 completed | "Counter" |
| `ach.math_addition_done` | All M06–M12 completed | "Adder" |
| `ach.math_subtraction_done` | All M13–M17 completed | "Subtracter" |
| `ach.math_patterns_done` | All M18–M21 completed | "Pattern Spotter" |
| `ach.math_time_money_measure_done` | All M22–M25 completed | "Everyday Math" |
| `ach.english_naming_done` | All E01–E07 completed | "Word Finder" |
| `ach.english_action_done` | All E08–E11 completed | "Action Star" |
| `ach.english_sequence_done` | All E12–E15 completed | "First, Next, Last" |
| `ach.life_morning_done` | All L01–L04 completed | "Morning Champion" |
| `ach.life_household_done` | All L05–L07 completed | "Helper Hands" |
| `ach.life_outdoors_done` | All L08–L10 completed | "Outdoor Explorer" |
| `ach.three_stars` | Any level earned 3 stars | "Star!" |
| `ach.all_three_stars` | All 50 levels earned 3 stars | "Pip's Helper" |
| `ach.returned_7` | Returned 7 distinct days | "A Week With Pip" |
| `ach.returned_30` | Returned 30 distinct days | "Pip's Friend" |

---

## Unlocking Logic

```
Level L is unlocked if and only if:
  - L is the first level in its area (M01, E01, L01), OR
  - The previous level (L-1) has been completed (≥ 1 star), OR
  - All levels in the previous cluster within the area have been completed
```

For Math (5 clusters), each cluster is gated by the previous cluster's
completion. Within a cluster, levels are linear.

For English (3 clusters), same pattern.

For Life Skills (3 clusters), same pattern.

---

## Achievements Scene

`AchievementsScene` displays all 16 achievements as a 4×4 grid of cards:

- Earned: full-color icon + name
- Locked: gray silhouette + name ("???" hidden until earned)

Tapping a card shows the achievement description and the date earned.

---

## Source

- `bunny iOS/Services/ProgressStore.swift`
- `bunny iOS/Scenes/AchievementsScene.swift`

---

## Anti-Patterns

| Pattern | Why wrong |
|---|---|
| Daily streak that resets on a missed day | Punishes real-life schedule |
| Showing "0/3 stars" for a not-yet-attempted level | Implies failure |
| XP bar | Gamifies, distracts from tasks |
| Time-limited "double XP" events | Manipulative |
| Leaderboards | Privacy + competition inappropriate for age |

---

## Acceptance Criteria

- [ ] Completing a level unlocks the next level
- [ ] Replaying a 3-star level keeps stars at 3
- [ ] Replaying a 1-star level can upgrade to 2 or 3 stars
- [ ] All 16 achievements are documented and reachable
- [ ] `AchievementsScene` shows earned achievements in color and locked in gray

---

## Open Questions

- Should we add "category completion" achievements (e.g., "Completed all
  Math scenes with 3 stars")? Tracked as v2 enhancement.

Last updated: 2026-01
