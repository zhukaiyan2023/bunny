# Life Skills System — GDD

**System slug**: SYS-GP-003
**Status**: Approved (v1.0)
**Pillars served**: Pillar 2 (Tasks), Pillar 5 (Adult-gated — life-skills is co-played with a parent)
**Last updated**: 2026-01

---

## Overview

The Life Skills System owns the 10 life-skills scenes (L01–L10). It teaches
**morning routines, hygiene, household chores, and outdoor safety**
through Pip's day. Unlike Math and English, these scenes are designed to
be **played with a parent** — the parent and child discuss what Pip should
do, then the child performs the action in-app, then they try it in real life.

---

## Requirements

| ID | Requirement |
|---|---|
| **TR-LIFE-001** | The system MUST support 10 distinct life-skills levels grouped into 3 clusters. |
| **TR-LIFE-002** | Every life-skills scene MUST end with a "try it IRL" prompt that kids can do with their parent. |
| **TR-LIFE-003** | Every life-skills scene MUST use `ImmersiveMissionScene` as the runtime (a long-form narrative scene). |
| **TR-LIFE-004** | Difficulty MUST scale via `LevelDefinition.difficulty` (1–5) — sequence length, not concept. |
| **TR-LIFE-005** | The system MUST NOT include any safety-critical content (e.g., "what to do in a fire"). Those are out of scope; this is a habit-forming app, not a safety manual. |
| **TR-LIFE-006** | The system MUST NOT collect data about whether the parent/child did the IRL task. |

---

## Concept Clusters

| Cluster | Level IDs | Scenario |
|---|---|---|
| **Morning Routine** | L01–L04 | Wake up, brush teeth, get dressed, eat breakfast |
| **Household** | L05–L07 | Set table, put away laundry, clean bedroom |
| **Outdoors** | L08–L10 | Cross the street, play at the playground, help a neighbor |

---

## Interaction Pattern

Life-skills scenes use **`ImmersiveMissionScene`** — a guided multi-step
narrative where Pip walks through the activity in 3–7 steps. Each step:

1. Pip narrates the next action ("Let's brush our teeth!")
2. The child taps the right object (toothbrush, toothpaste, sink, etc.)
3. Pip celebrates ("Sparkly smile!")
4. The next step appears

After the in-app mission completes, the scene shows a "**Try it IRL!**" card
suggesting the family do the same routine together.

---

## Source

- `bunny iOS/Scenes/LifeSkillsGameScene.swift`
- `bunny iOS/Scenes/ImmersiveMissionScene.swift`
- `bunny iOS/Models/HomeMissionSpec.swift`
- `bunny iOS/Resources/levels.json` (entries L01–L10)

---

## "Try It IRL" Cards

Each life-skills scene ends with a card:

```
┌──────────────────────────────────────────┐
│  🌟 Great job helping Pip!                │
│                                            │
│  Try it for real:                          │
│  "Let's brush our teeth together —         │
│   top teeth, then bottom teeth!"           │
│                                            │
│  [ Done ]   [ Play again ]                │
└──────────────────────────────────────────┘
```

These cards are **prompts for parent-child conversation**, not checklists.
bunny never tracks whether the family did the IRL task.

---

## Acceptance Criteria

- [ ] All 10 levels in `levels.json` map to a Life-Skills scene type
- [ ] Every life-skills scene uses `ImmersiveMissionScene`
- [ ] Every life-skills scene ends with a "Try it IRL" card
- [ ] No life-skills scene includes safety-critical instructions
- [ ] The "Try it IRL" prompt is short (≤ 12 words)

---

## Pillar Notes

Life-skills is where **Pillar 5** matters most: the app is co-played. The
parent is **expected to be present**. The UI does not require the parent to
read text the child might object to, and the parent is never asked to
perform in-app tasks on behalf of the child.

---

## Open Questions

- Should we add a "Family Challenge" weekly prompt (e.g., "This week, help
  set the table every night")? Tracked as v2 feature.

Last updated: 2026-01
