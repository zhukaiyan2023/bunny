# Accessibility in bunny

Last verified: 2026-01

bunny targets children ages 4–7. Accessibility is non-optional — kids with low
vision, motor difficulties, or cognitive load issues must be able to enjoy the
same scenes.

## VoiceOver / Spoken Prompts

- Every scene must expose a spoken prompt via `SpeechService.speak(_:)`.
- Spoken prompts use **plain language** (no jargon).
- Voice actor: `AVSpeechSynthesisVoice(language: "en-US")` with rate 0.45.
- Tap the **speaker icon** to re-hear the prompt (implemented in `SKHUD`).

## Dynamic Type

- All `SKLabelNode` fonts derive from `SKTheme.bodyFont(size:)` which respects
  the user's preferred content size category.
- Minimum text size: 24pt (iOS points) — readable for ages 4–7 on any device.
- Maximum text size: 60pt — large enough for low vision without overflowing
  scene layouts.

## Reduce Motion

- Respect `UIAccessibility.isReduceMotionEnabled`.
- When enabled, replace movement animations with cross-fades and reduce
  particle counts to 25% of normal.
- Implemented via `SKBridge.applyMotionPreferences(to:)` called in every
  scene's `didMove(to:)`.

## Reduce Transparency

- Increase background opacity to 1.0 (no translucent overlays) when
  `UIAccessibility.isReduceTransparencyEnabled`.

## Color Independence

- Never use color alone to convey meaning (e.g., "tap the red cup"). Pair
  color with shape, label, or speech.
- Test every scene in grayscale before merging.

## Parental Controls

- A **math gate** challenge appears whenever the player taps "Parent
  Dashboard" — verifies an adult is at the device.
- `ParentGateScene` is a single-digit × single-digit multiplication. Adults
  can disable it via Settings (not yet implemented; tracked as future work).
- "Reset Progress" inside the Parent Dashboard requires the gate twice.

## Touch Targets

- Minimum touch target: 80 × 80 points (Apple's default is 44 × 44; we
  exceed for child fingers).
- Spacing between touch targets: ≥ 16 points.

## Captions

- Spoken prompts are also displayed as text labels in the HUD.
- Sound effects have no spoken analog but their source object is always
  visually highlighted before the sound plays.

## Testing Checklist

Before merging a scene, verify:

- [ ] VoiceOver reads the scene's prompt correctly
- [ ] Dynamic Type (largest setting) does not overflow the scene
- [ ] Reduce Motion is honored
- [ ] Color-blind safe palette in use (test with Color Oracle)
- [ ] Touch targets ≥ 80×80
- [ ] Sound effects are paired with visual cues

Last verified: 2026-01
