# Accessibility System — GDD

**System slug**: SYS-FOUND-004
**Status**: Approved (v1.0)
**Pillars served**: Pillar 1 (Calm), Pillar 5 (Adult-gated)
**Last updated**: 2026-01

---

## Overview

bunny serves children ages 4–7 with a wide range of abilities. The
Accessibility System ensures every child — including those with low
vision, motor difficulties, hearing differences, or cognitive load
issues — can complete every scene.

This system is cross-cutting: it touches every scene and every UI
component. The Accessibility System is the **single source of
guidance** for what "accessible" means in bunny.

---

## Requirements

| ID | Requirement |
|---|---|
| **TR-A11Y-001** | Every scene MUST work end-to-end with VoiceOver enabled. |
| **TR-A11Y-002** | Every `SKLabelNode` MUST have a non-empty `accessibilityLabel`. |
| **TR-A11Y-003** | Every interactive node MUST be reachable via VoiceOver and announce its purpose. |
| **TR-A11Y-004** | Touch targets MUST be ≥ 80 × 80 points (exceeds Apple HIG minimum of 44). |
| **TR-A11Y-005** | Spacing between touch targets MUST be ≥ 16 points. |
| **TR-A11Y-006** | Reduce Motion MUST be honored: replace movement animations with cross-fades; reduce particles to 25%. |
| **TR-A11Y-007** | Reduce Transparency MUST increase background opacity to 1.0. |
| **TR-A11Y-008** | Color MUST NEVER be the sole carrier of meaning. Pair with shape, label, or speech. |
| **TR-A11Y-009** | Dynamic Type MUST scale all in-scene text from xSmall (24pt) to xxxLarge (60pt). |
| **TR-A11Y-010** | All spoken prompts MUST also appear as text labels in the HUD. |
| **TR-A11Y-011** | `UIAccessibility.post(notification: .announcement, ...)` MUST be used for important state changes. |

---

## VoiceOver

Every scene's primary instruction is announced automatically. Example for
`MathGameScene`:

```
"Hold on a moment. Welcome to Bakery Box Rescue. Help Pip pack three
croissants into the box. Tap a croissant to add it to the box."
```

VoiceOver hint order:
1. Scene title
2. One-sentence instruction
3. List of interactive elements
4. Reward / progress state (if relevant)

---

## Dynamic Type

`SKTheme` exposes size-aware fonts:

```swift
extension SKTheme {
    static func bodyFont(size: CGFloat) -> String   // "AvenirNext-Regular"
    static func headlineFont(size: CGFloat) -> String // "AvenirNext-DemiBold"
}
```

Every scene reads the user's preferred content size category and selects
font sizes from a lookup table:

| Category | Body | Headline |
|---|---|---|
| xSmall | 24pt | 32pt |
| Small | 28pt | 36pt |
| Medium (default) | 32pt | 44pt |
| Large | 38pt | 52pt |
| xLarge | 46pt | 60pt |
| xxLarge / xxxLarge | 54pt / 60pt | 60pt / 60pt |

Scenes must lay out within their bounds at the largest size — no clipping.

---

## Reduce Motion

When `UIAccessibility.isReduceMotionEnabled == true`:

- Replace `SKAction.move(...)` with `SKAction.fadeIn(withDuration: 0.2)`
- Reduce particle emitter birth rate to 25% of normal
- Disable `SKAction.scale(...)` (snap to final size)
- Replace `SKTransition.push(...)` with `SKTransition.fade(...)`
- Disable Pip's bounce animation on the reward screen
- All background "floating" ambient motion stops

Implemented in `SKBridge.applyMotionPreferences(to:)` called in every
scene's `didMove(to:)`.

---

## Color Independence

| Signal | Color | Paired with |
|---|---|---|
| Correct | Sage green | A star appears |
| Try again | Dusty pink | Pip says "Let's try again" |
| Hint | Cream highlight | Text label "Hint" |

Test every scene in grayscale before merge.

---

## Touch Targets

`SKButton` enforces a minimum 80×80 hit area even if its visual is smaller.
Padding is invisible (clear nodes) but extends the hit zone.

---

## Captions

Every spoken prompt also appears as text in the HUD. Sound effects are
paired with visual cues (a star pops up for "correct", a heart icon for
"good try").

---

## Testing Checklist

Before merging any scene:

- [ ] VoiceOver reads the scene's primary prompt
- [ ] VoiceOver reaches every interactive node
- [ ] Dynamic Type at xxxLarge does not overflow
- [ ] Reduce Motion is honored
- [ ] Grayscale palette still differentiates states
- [ ] All touch targets ≥ 80×80

---

## Source

- `bunny iOS/UI/SKTheme.swift` (font sizing)
- `bunny iOS/UI/SKBridge.swift` (`applyMotionPreferences`)
- `bunny iOS/UI/SKButton.swift` (hit area)
- Cross-cutting across all scenes

---

## Acceptance Criteria

- [ ] Every scene passes a manual VoiceOver play-through
- [ ] Every scene renders cleanly at all Dynamic Type sizes
- [ ] Every scene honors Reduce Motion
- [ ] No scene relies on color alone
- [ ] CI test verifies `applyMotionPreferences` correctly modifies node actions

---

## Open Questions

- Should we add a "high contrast" theme for low-vision users? Tracked for v2.

Last updated: 2026-01
