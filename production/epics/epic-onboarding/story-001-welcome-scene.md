# Story S1-01 — WelcomeScene (First-Launch Greeting)

**Epic**: EPIC-001 — Onboarding & First-Run Experience
**Status**: Ready
**GDD req**: TR-ONB-001, TR-ONB-002
**ADR**: ADR-0002 (routing)
**Story type**: Feature
**Acceptance test**: integration + manual playtest

---

## Context

A new install currently drops the user straight into `MenuScene`. There
is no greeting, no introduction of Pip, and no sense that this is a
different kind of kids' app. The first 5 seconds matter — they set the
tone for everything.

This story adds `WelcomeScene`: a soft cream screen with Pip waving,
Pip saying "Hi! I'm Pip. Want to play with me?" via TTS, and a single
"Yes!" button that routes to M01 (the easiest Math level).

---

## Acceptance Criteria

- [ ] `WelcomeScene.swift` exists in `bunny iOS/Scenes/`
- [ ] `SceneRouter.Route` adds `.welcome` case
- [ ] On first launch, app routes to `.welcome` instead of `.menu`
- [ ] Welcome screen shows Pip sprite, greeting text, single "Yes!" button
- [ ] TTS speaks "Hi! I'm Pip. Want to play with me?" within 500 ms
- [ ] Tapping "Yes!" routes to `.scene(level: M01)`
- [ ] Tapping anywhere on the screen also routes to `.scene(level: M01)`
  (kid-friendly: don't make the kid hunt for the button)
- [ ] Speaker icon re-speaks the greeting on tap
- [ ] VoiceOver reads the greeting as a single label
- [ ] Reduce Motion replaces Pip's wave animation with a fade-in
- [ ] Touch target for "Yes!" is 80 × 80 minimum (use `SKButton`)

---

## Implementation Notes

- Subclass `SKScene`; follow the lifecycle contract in `scene-system.md`
- Add to all 3 targets via Xcode project membership
- Reuse `SKTheme.cream` background; reuse `SKButton` for the Yes button
- Reuse `SpeechService.shared.speak(...)` for the greeting

---

## Engine Risk

**Low** — follows established scene pattern.

---

## Out of Scope

- Back button (welcome screen has no back; tapping anywhere → M01)
- Skipping the greeting (we want every kid to hear it once)

---

## Test Evidence Path

`tests/integration/onboarding-first-launch.test.swift` — verifies route is
`.welcome` on first launch and `.menu` after `ProgressStore.onboardingComplete`
is set.
