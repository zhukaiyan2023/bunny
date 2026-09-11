# Math System — GDD

**System slug**: SYS-GP-001
**Status**: Approved (v1.0)
**Pillars served**: Pillar 2 (Tasks), Pillar 3 (Persistence)
**Last updated**: 2026-01

---

## Overview

The Math System owns the 25 math scenes in `levels.json` (M01–M25). It
delivers **counting, basic addition, basic subtraction, pattern
recognition, simple measurement, time-on-the-hour, and money recognition**
to children ages 4–7 through short, drag/tap interactions.

---

## Requirements

| ID | Requirement |
|---|---|
| **TR-MATH-001** | The system MUST support 25 distinct math levels grouped into 5 concept clusters (Counting, Addition, Subtraction, Patterns, Time/Money/Measure). |
| **TR-MATH-002** | Every math scene MUST be completable in 60–90 seconds. |
| **TR-MATH-003** | Every math scene MUST accept at least 3 distinct valid answers (e.g., "3", "three", or three finger taps). |
| **TR-MATH-004** | Difficulty MUST scale via the `difficulty` field (1–5) — concept stays the same, numeric range grows. |
| **TR-MATH-005** | The system MUST NOT include negative numbers, fractions, or any concept beyond Grade 2 curriculum. |
| **TR-MATH-006** | Scene audio MUST narrate the prompt and read out the child's answer when wrong. |
| **TR-MATH-007** | Wrong answers MUST be celebrated as attempts — "Good try! Let's count together." |

---

## Concept Clusters

The 25 math levels map to 5 clusters, each with a difficulty curve:

| Cluster | Level IDs | Concepts | Difficulty range |
|---|---|---|---|
| **Counting** | M01–M05 | Count objects 1–10, then 11–20 | 1–3 |
| **Addition** | M06–M12 | Combine sets (sums ≤ 5, then ≤ 10, then ≤ 15) | 2–3 |
| **Subtraction** | M13–M17 | Take away (differences ≤ 5, then ≤ 10) | 2–3 |
| **Patterns** | M18–M21 | ABAB, ABC, growing patterns | 3–4 |
| **Time / Money / Measure** | M22–M25 | Hour hand, coin values, length comparison | 3–5 |

---

## Interaction Patterns

Each math scene uses **one of three interaction patterns**:

1. **Count-and-tap** — child taps each object as Pip counts aloud
   ("one… two… three… now how many?"). Used in Counting.
2. **Drag-to-combine** — child drags objects onto a target container
   (e.g., 2 apples + 3 apples → "how many now?"). Used in Addition /
   Subtraction.
3. **Tap-the-next** — child taps the next item in a pattern (e.g., red,
   blue, red, blue, **?**). Used in Patterns.

Time / Money / Measure use a hybrid of count-and-tap with a clock face /
coin layout / length bar.

---

## Difficulty Curve

Within each cluster, the difficulty field controls numeric range:

| Difficulty | Counting | Addition | Subtraction | Patterns |
|---|---|---|---|---|
| 1 | 1–3 | sums ≤ 3 | diff ≤ 3 | AB only |
| 2 | 1–5 | sums ≤ 5 | diff ≤ 5 | ABAB |
| 3 | 1–10 | sums ≤ 10 | diff ≤ 10 | ABC |
| 4 | 1–15 | sums ≤ 15 | diff ≤ 10 | growing |
| 5 | 1–20 | sums ≤ 20 | diff ≤ 15 | nested |

---

## Spaced Repetition

Levels unlock in **linear order within each cluster** (M01 → M02 → …). A
child cannot skip ahead within a cluster. Once a cluster is complete, the
next cluster is freely accessible from the area hub.

**No retention pressure**: a child may replay any completed level as many
times as they like. Star ratings are recorded as the **max** ever earned,
never overwritten downward.

---

## Source

- `bunny iOS/Scenes/MathGameScene.swift`
- `bunny iOS/Scenes/GameSceneFactory.swift`
- `bunny iOS/Resources/levels.json` (entries M01–M25)

---

## Visual Style

Math scenes use:
- Background: `MathBakery`, `MathMarket`, `MathFestival`, `MathOutdoors`,
  `MathSpace` illustrations
- Numerals: `SKLabelNode` with `SKTheme.headlineFont(size:)` (60pt default)
- Objects: `SKSpriteNode` from the `PipHero` and per-scene asset sets
- Counters: `SKShapeNode` rings drawn around the correct count

---

## Acceptance Criteria

- [ ] All 25 levels in `levels.json` map to a Math scene type
- [ ] Every Math scene plays an opening narration via `SpeechService`
- [ ] Replay of a Math scene never decreases the stored star rating
- [ ] Average completion time per scene is 60–90s (measured via manual playtest)
- [ ] No Math scene requires reading more than 4-letter words

---

## Open Questions

- Should we add a "Math Stories" mode that merges counting + addition into
  word problems? Deferred to v2.

Last updated: 2026-01
