# English System — GDD

**System slug**: SYS-GP-002
**Status**: Approved (v1.0)
**Pillars served**: Pillar 2 (Tasks), Pillar 3 (Persistence)
**Last updated**: 2026-01

---

## Overview

The English System owns the 15 English / vocabulary scenes in `levels.json`
(E01–E15). It teaches **object naming, action words, sequencing, and
prepositions** through Pip's daily activities (breakfast, getting dressed,
bath time, etc.).

---

## Requirements

| ID | Requirement |
|---|---|
| **TR-ENG-001** | The system MUST support 15 distinct English levels grouped into 3 concept clusters. |
| **TR-ENG-002** | Every English scene MUST have at least 3 vocabulary words in its `LevelDefinition.vocabulary` array. |
| **TR-ENG-003** | Every word MUST be pronounced via `SpeechService.speak(...)` at least once per scene. |
| **TR-ENG-004** | Every English scene MUST accept **any** of the vocabulary items as a valid interaction target. |
| **TR-ENG-005** | Difficulty MUST scale via `LevelDefinition.difficulty` (1–5). |
| **TR-ENG-006** | The system MUST NOT include words longer than 6 letters. |
| **TR-ENG-007** | The system MUST NOT require typing — all interactions are tap or drag. |
| **TR-ENG-008** | Wrong answers MUST repeat the word and offer another chance ("That was the milk. Can you find the cup?"). |

---

## Concept Clusters

| Cluster | Level IDs | Concepts | Vocabulary examples |
|---|---|---|---|
| **Object Naming** | E01–E07 | Common household objects | milk, cup, bowl, spoon, bed, towel |
| **Action Words** | E08–E11 | Verbs in context | wash, pour, brush, dress |
| **Sequencing** | E12–E15 | First / next / last | wake, eat, play, sleep |

---

## Interaction Patterns

1. **Find-the-object** — "Find the cup" → child taps the cup among
   distractors. Used in Object Naming.
2. **Do-the-action** — "Pour the milk" → child drags the milk carton over
   the cup. Used in Action Words.
3. **Order-the-steps** — "What comes first?" → child taps the first step in
   a 3-step sequence. Used in Sequencing.

---

## Source

- `bunny iOS/Scenes/EnglishGameScene.swift`
- `bunny iOS/Models/EnglishActionProgress.swift`
- `bunny iOS/Models/EnglishSceneAction.swift`
- `bunny iOS/Models/SceneLessonPlan.swift`
- `bunny iOS/Resources/levels.json` (entries E01–E15)

---

## Speech Behavior

- The scene's `instruction` is spoken once at scene entry.
- The first time a word appears as an interaction target, it is spoken
  aloud (TTS rate from `ProgressStore.shared.ttsRate`).
- A **speaker icon** in the HUD re-speaks the prompt on tap.
- The child's wrong answer is read back: "That was the **spoon**."

---

## Visual Style

English scenes use the same illustration set as Life Skills (Bedroom,
Bathroom, Kitchen, etc.) because the scenarios are Pip's daily activities.
The English system **layers vocabulary prompts over the same scenes**.

---

## Acceptance Criteria

- [ ] All 15 levels in `levels.json` map to an English scene type
- [ ] Every vocabulary word is pronounced at least once per scene
- [ ] Replay of an English scene never decreases the stored star rating
- [ ] Average completion time per scene is 60–90s
- [ ] No English scene requires reading more than 4-letter words
- [ ] Speaker icon re-speaks the prompt within 200 ms of tap

---

## Open Questions

- Should we record a real child voice for the v2 release? (Tracked.)

Last updated: 2026-01
