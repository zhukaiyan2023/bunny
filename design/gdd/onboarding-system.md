# Onboarding System — GDD

**System slug**: SYS-PLAYER-001
**Status**: Approved (v1.0)
**Pillars served**: Pillar 1 (Calm — first impression), Pillar 5 (Adult-gated — first-run parent gate)
**Last updated**: 2026-01

---

## Overview

The Onboarding System walks a new player (and parent) through the first
3 scenes and a brief parent primer. It is the **first 5 minutes** of the
app and sets the tone for everything that follows.

---

## Requirements

| ID | Requirement |
|---|---|
| **TR-ONB-001** | On the first launch, the app MUST show a brief welcome scene with Pip speaking. |
| **TR-ONB-002** | The first scene played MUST be M01 (Bakery Box Rescue) — easiest, friendliest. |
| **TR-ONB-003** | After M01, the app MUST offer the parent a one-time setup primer behind the parent gate. |
| **TR-ONB-004** | The primer MUST show: how to adjust TTS rate, how to set the daily session cap, how to find the parent dashboard. |
| **TR-ONB-005** | After onboarding, `ProgressStore.onboardingComplete` MUST be set to `true`. |
| **TR-ONB-006** | Re-launching the app MUST skip onboarding entirely. |
| **TR-ONB-007** | Resetting progress MUST also reset the onboarding flag (so a hand-off device restarts onboarding). |

---

## Onboarding Flow

```
First launch
    │
    ▼
WelcomeScene (NEW)
    "Hi! I'm Pip. Want to play with me?"
    [ Yes! ]  →  M01 (Bakery Box Rescue)
    │
    ▼
After M01 complete
    │
    ▼
ParentPrimerScene (NEW)
    "Quick note for grown-ups: here's how to
     find the parent area, adjust sound, and
     set a daily limit."
    [ Show me ]  →  ParentGateScene → ParentDashboardScene
    [ Later ]    →  MenuScene (skip primer)

Subsequent launches
    │
    ▼
MenuScene (direct — no onboarding)
```

---

## Welcome Scene (to be implemented)

```
┌──────────────────────────────────────────┐
│                                            │
│              🐰  (Pip waving)              │
│                                            │
│         "Hi! I'm Pip."                     │
│       "Want to play with me?"              │
│                                            │
│              [ Yes! ]                      │
└──────────────────────────────────────────┘
```

- Voice: Pip says "Hi! I'm Pip. Want to play with me?"
- Background: animated soft cream gradient
- Single large button (entire screen is tappable too)
- No settings, no parent area on this screen (kid-only path)

---

## Parent Primer Scene (to be implemented)

A short, scrollable text card with 3 sections:

1. **How to find the parent area** — tap the small icon in the bottom-left
   of the menu screen; solve a multiplication puzzle
2. **How to adjust the speech speed** — open Settings inside the parent
   area; drag the TTS rate slider
3. **How to set a daily limit** — open Settings; pick 5 / 10 / 15 / 20 / 30 min
4. **Privacy** — bunny collects nothing; all progress stays on this device

Two buttons: "Show me" (opens parent area) and "Later" (returns to menu).

---

## Acceptance Criteria

- [ ] First launch shows welcome → M01 → parent primer
- [ ] Subsequent launches go directly to menu
- [ ] Reset progress triggers onboarding on next launch
- [ ] Welcome scene speaks the greeting via TTS within 500 ms

---

## Open Questions

- Should we include a video tutorial? (Tracked as v2 enhancement — keep
  v1 text + TTS only.)

Last updated: 2026-01
