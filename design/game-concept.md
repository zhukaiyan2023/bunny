# Game Concept — bunny

**Status**: Approved (v1.0)
**Author**: bunny team
**Last updated**: 2026-01
**Working dir**: `/Users/kaiyan/Documents/bunny`

---

## One-line Pitch

A gentle, parent-approved iPad-first edutainment app where Pip the bunny
guides children ages 4–7 through 50 short, hand-directed learning scenes —
Math, English, and everyday Life Skills — each scene completing in under 90
seconds.

---

## Elevator Pitch

bunny is the daily 10-minute companion for kids ages 4–7 who are learning to
read, count, and navigate their day. Every day, Pip invites the child into a
small, hand-drawn world — a bakery, a bedroom, a market — and walks them
through one tiny task: count three croissants, sound out "spoon", remember
to brush your teeth.

There is no failure, no timer pressure, no loot box. Stars are awarded for
finishing a scene; they are not subtracted for trying again. Every scene
runs in under 90 seconds so a tired child can finish one before bed.

Parents open a separate dashboard behind a multiplication gate to see what
their child practiced, reset progress, and adjust the daily cap.

---

## Target Audience

### Primary player
- **Age**: 4–7 years old
- **Reading level**: pre-reader to early reader (some 3-letter words)
- **Tech comfort**: familiar with iPad; uses apps independently with supervision
- **Attention span**: 5–15 minutes per session
- **Motivation**: wants to help Pip; enjoys "doing tasks" like a grown-up

### Secondary player (gatekeeper)
- **Age**: 28–45
- **Role**: parent, grandparent, educator
- **Concerns**: screen time, educational value, data privacy (COPPA), no ads, no IAP pressure
- **Needs**: simple progress dashboard, ability to limit session length, no ads or chat

---

## Player Fantasy

> "I'm helping Pip with real things — making breakfast, getting dressed,
> counting cookies. I'm a big kid."

The child is not "playing a game"; the child is **doing things alongside a
friend**. Pip is a peer, not a teacher. The child succeeds because they
tried; the system rewards persistence, not correctness.

---

## Core Loop

```
        ┌─────────────────────────────┐
        │  Pick an area (Math /       │
        │  English / Life Skills)     │◀─────────┐
        └──────────────┬──────────────┘          │
                       ▼                          │
        ┌─────────────────────────────┐          │
        │  Pick a level (1–50)        │          │
        │  (or accept Pip's suggestion)│          │
        └──────────────┬──────────────┘          │
                       ▼                          │
        ┌─────────────────────────────┐          │
        │  Watch Pip's spoken prompt  │          │
        │  (tap speaker to repeat)    │          │
        └──────────────┬──────────────┘          │
                       ▼                          │
        ┌─────────────────────────────┐          │
        │  Tap / drag to complete the │          │
        │  one small task             │          │
        └──────────────┬──────────────┘          │
                       ▼                          │
        ┌─────────────────────────────┐          │
        │  Pip celebrates; star       │          │
        │  awarded; gentle feedback   │          │
        └──────────────┬──────────────┘          │
                       ▼                          │
        ┌─────────────────────────────┐          │
        │  Tap "Next" → next level    │──────────┘
        │  OR tap "Map" → area map
        └─────────────────────────────┘
```

**Session shape**: a typical session is **3–7 scenes** (10–12 minutes).
A child is gently nudged to stop after 10 minutes via a soft chime + Pip
saying "Let's play again tomorrow!" — never a hard lock.

---

## Why Now, Why This

1. **COPPA-safe edutainment is underserved.** Most "free" kids' apps are
   ad-supported or harvest data. Parents will pay for an honest, quiet,
   single-purpose app.
2. **iPad is the natural device** for kids ages 4–7 — large touch targets,
   parental controls, no phone distractions.
3. **Apple's focus on privacy + accessibility** (VoiceOver, Reduce Motion,
   Guided Access) aligns perfectly with this audience.
4. **SpriteKit + Swift is a low-friction stack** — one developer can ship
   across iPhone, iPad, Mac, and Apple TV from a single codebase.

---

## What Makes bunny Different

| Most kids' apps | bunny |
|---|---|
| Loud colors, fast animations, flashing rewards | Calm pastel palette, gentle motion, soft sounds |
| Multiple-choice quiz format | Drag-and-drop / tap-the-object interactions |
| Streak punishment (lose streak if you miss a day) | Never punish. Coming back is always good. |
| Ads and IAP pressure | No ads, no IAP, no social features |
| Generic cartoon voice | Warm, child-appropriate TTS with adjustable rate |
| Single platform | Native on iPhone, iPad, Mac, Apple TV |
| Tracks child behavior to advertisers | Zero tracking. COPPA-safe by design. |

---

## Scope Boundaries

### In scope (MVP)
- 50 hand-authored scenes (25 Math, 15 English, 10 Life Skills) — **already authored in `levels.json`**
- One protagonist (Pip), one narrator voice (system TTS)
- Three learning areas with area hubs and level maps
- Reward system: 1–3 stars per level, no penalties
- Parent dashboard behind a multiplication gate
- Achievement scene
- Settings: TTS rate, motion toggle, daily session cap
- English copy; no localization in v1

### Explicitly out of scope (v1)
- Multiplayer / social
- User-generated content
- In-app purchases
- Ads of any kind (interstitial, banner, rewarded video)
- Analytics or telemetry
- Cloud save / cross-device sync
- Character customization
- New levels via downloadable content
- Push notifications

### Future considerations (v2+)
- Localization (Spanish, French, Mandarin)
- New areas (Music, Science, Coding)
- Custom avatar for the child
- Pre-recorded voice for premium feel
- Apple Watch parent companion

---

## Success Metrics (qualitative)

bunny is successful if:

1. **A 4-year-old can complete a scene without adult help** (after one
   onboarding play-through with the parent).
2. **A 7-year-old comes back voluntarily the next day.**
3. **A parent reads the privacy page and feels safe** — there is no
   tracking, no ads, no IAP, no chat.
4. **App Store reviews mention "calm", "gentle", "no ads", or "my kid
   loves Pip".**

bunny is **not** optimizing for DAU, retention curves, or session length —
these metrics are inappropriate for this audience.

---

## Inspirations & References

| Reference | What we take from it |
|---|---|
| **Sago Mini** | Calm pastel palette, single-task scenes, no failure |
| **Toca Boca** | Open-ended exploration within a task |
| **Daniel Tiger's Neighborhood** | Warm narrator voice, real-life scenarios |
| **Khan Academy Kids** | Free, no ads, parent dashboard |
| **Pok Pok** | Hand-drawn feel, no language required |
| **Highlights Hidden Pictures** | Quiet, focused, kid-led |

What we **don't** take: timers, lives, streaks, unlockables, scoreboards,
character customization.

---

## Open Questions

None for v1. All open design questions have been resolved or pushed to
the appropriate GDD.

Last updated: 2026-01
