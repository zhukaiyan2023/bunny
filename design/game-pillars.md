# Game Pillars — bunny

**Status**: Approved (v1.0)
**Last updated**: 2026-01

These five pillars are the **design anchors** for every decision in bunny.
When a design choice conflicts with a pillar, **the pillar wins** — and
the pillar itself must be revisited explicitly (via ADR or pillar review)
before the design choice can proceed.

The pillars are **prioritized in order**. When two pillars conflict, the
earlier pillar wins.

---

## Global Tone — Immersive, Living Scenes

**"The child enters a world, not a picture."**

bunny's scenes should feel immersive through composition and responsive
detail. A scene is not a single static background image: it is a layered
environment made from a background layout plus individually authored elements
(characters, props, foreground shapes, lighting, and ambient details). Each
element may have its own gentle motion, and the scene should respond to the
story's current context as it unfolds.

### Direction

- Build each scene as a readable spatial layout with foreground, middle
  ground, and background relationships — not as one flat backdrop.
- Give meaningful elements independent behavior where appropriate: Pip can
  react, props can move, and ambient details can breathe or shift.
- Let story and interaction state drive changes in pose, placement, emphasis,
  lighting, and motion. The environment should visibly acknowledge what the
  child is doing and what is happening in the story.
- Keep all changes calm, legible, and purposeful. Motion should support the
  child's attention and sense of presence, never compete with the task.
- Preserve accessibility: respect Reduce Motion, keep prompts and targets
  clear above the environment, and never rely on animation alone to convey
  meaning.

### Decision test

> "If every character and prop stopped moving, would this still be only a
> background image?" If yes → add spatial structure, authored elements, or
> context-driven behavior that makes the scene feel alive.

This is a **cross-cutting visual direction**, not a sixth priority pillar.
When it conflicts with the pillars, the prioritized pillars win — especially
Pillar 1 (Calm over Exciting).

---

## Pillar 1 — Calm over Exciting

**"Bunny should never shout."**

The visual palette is muted pastel. Audio is gentle (no startle stings,
no rapid-fire SFX). Motion is slow and smooth. There are no flashing
animations, no "energy" bars, no "boss" reveals.

### Implication examples
- ❌ Don't add a "level up!" fanfare. ❌ Don't add particle explosions on
  completion. ❌ Don't use bright red or yellow for accents.
- ✅ Use soft chime on completion. ✅ Use cream / sage / dusty pink palette.
  ✅ Use 250–400ms ease-in-out transitions.

### Decision test
> "Would this feature make a tired 5-year-old feel overwhelmed?"
> If yes → cut it.

---

## Pillar 2 — Tasks over Games

**"The child is doing real things, not playing a game about doing real things."**

bunny is structured around **small, real-world tasks**: count three
croissants, sound out "spoon", remember to brush teeth. There are no
"levels" in the game-design sense; there are **scenes** that correspond
to real cognitive tasks.

### Implication examples
- ❌ Don't add a "game over" screen. ❌ Don't add lives. ❌ Don't add a
  coin / currency system. ❌ Don't add XP.
- ✅ Add stars as quiet recognition. ✅ Allow infinite retries. ✅ Use the
  reward scene as a celebration of finishing, not a scoreboard.

### Decision test
> "Is this feature about winning/losing, or about doing a task?"
> If winning/losing → cut it.

---

## Pillar 3 — Persistence over Performance

**"Trying again is always the right answer."**

bunny never punishes slow play, wrong answers, or coming back tomorrow.
There are no "missed day" penalties. There is no "best score" record.

### Implication examples
- ❌ Don't show "best time" on a level. ❌ Don't show "you got 2 stars last
  time, can you get 3?". ❌ Don't reduce hearts / lives.
- ✅ Show the highest star count ever earned (and never decrease it).
  ✅ Re-show the spoken prompt if the child idles. ✅ Encourage "let's try
  again!" rather than "wrong!".

### Decision test
> "Does this feature praise persistence or punish performance?"
> If punish → invert it.

---

## Pillar 4 — Privacy by Default

**"The child cannot be tracked, profiled, advertised to, or shared."**

bunny collects nothing. There is no analytics SDK, no ad network, no
social graph, no remote logging. All progress is stored locally on the
device. Parent data is on the device too.

### Implication examples
- ❌ Don't add Firebase / Amplitude / Mixpanel. ❌ Don't add "share to
  parent" social features. ❌ Don't collect device IDs.
- ✅ Document the privacy stance in the App Store listing. ✅ Use
  `UserDefaults` only. ✅ Never make a network call from the app.

### Decision test
> "If a parent reads the App Store privacy label, would they be surprised
> by any data leaving the device?"
> If yes → remove it.

---

## Pillar 5 — Adult-Free for the Child, Adult-Gated for the Parent

**"A 4-year-old can play alone; a parent cannot be tricked into a purchase."**

The child should be able to launch bunny and play without encountering any
text a parent must read, any decision that requires adult judgment, or any
external link. The parent gets a separate, clearly-marked dashboard behind
a multiplication gate.

### Implication examples
- ❌ Don't put settings on the main menu. ❌ Don't link to the App Store.
  ❌ Don't show ads. ❌ Don't require login.
- ✅ Put the parent area behind `ParentGateScene` (single-digit × single-digit).
  ✅ Use App Store parental controls as a backstop. ✅ Keep all copy at a
  4-year-old's reading level on the child's path.

### Decision test
> "Could a 4-year-old accidentally trigger this, or could a parent
> accidentally miss this?"
> Fix whichever direction the failure is in.

---

## Pillars in Priority Order

When pillars conflict, the **earlier pillar wins**:

1. **Calm** > **Tasks** > **Persistence** > **Privacy** > **Adult-gated**

In practice this rarely matters — the pillars are designed to be
mutually reinforcing. The priority order only matters in edge cases,
e.g., if a feature would make the app calmer (Pillar 1) but introduce a
scoreboard (Pillar 2), Pillar 1 wins.

---

## Anti-Pillars (what we explicitly reject)

For every decision, also ask:

- ❌ **Are we adding a "game" mechanic that doesn't serve a real task?**
  If yes → cut.
- ❌ **Are we adding anything that requires a network call?**
  If yes → cut.
- ❌ **Are we adding anything that requires a child to read text the
  parent might disagree with?** If yes → cut.
- ❌ **Are we adding anything where the child loses (rather than the
  child tries again)?** If yes → cut.

---

## Pillars in the GDDs

Every GDD section should reference which pillar(s) it serves. For example:

- `math-system.md` → Pillar 2 (Tasks), Pillar 3 (Persistence — retry is
  free)
- `audio-system.md` → Pillar 1 (Calm — quiet audio)
- `parent-system.md` → Pillar 5 (Adult-gated)
- `accessibility-system.md` → Pillar 1 (Calm — respects Reduce Motion)
- `reward-system.md` → Pillar 2 (Tasks — star = finished, not won)

---

## When to Revisit a Pillar

Pillars should be revisited when:

- The pillar is preventing a feature that would clearly serve the player
  better.
- New platform constraints (e.g., a regulatory requirement) conflict
  with a pillar.
- Playtesting data shows the pillar is being misinterpreted.

A pillar revision is a **major design change** and should be:
- Captured as an ADR or in this file directly
- Reviewed by the full team
- Communicated to anyone currently implementing against the pillar

Last updated: 2026-09
