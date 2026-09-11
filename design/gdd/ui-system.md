# UI System — GDD

**System slug**: SYS-EXP-003
**Status**: Approved (v1.0)
**Pillars served**: Pillar 1 (Calm)
**Last updated**: 2026-01

---

## Overview

The UI System provides **themed, reusable UI primitives** that every scene
uses. Centralizing UI in `bunny iOS/UI/` keeps the visual identity
consistent, makes accessibility easy to enforce, and lets designers
re-skin the app by editing one file.

---

## Components

| Component | File | Purpose |
|---|---|---|
| `SKTheme` | `SKTheme.swift` | Colors, fonts, paddings, animation durations |
| `SKButton` | `SKButton.swift` | Tap-target node with hit area + callback |
| `SKCard` | `SKCard.swift` | Rounded background card with title + body |
| `SKHUD` | `SKHUD.swift` | Heads-up display: prompt text, speaker icon, progress dots |
| `SKLayout` | `SKLayout.swift` | Constraint-style helpers for laying out nodes |
| `SKBridge` | `SKBridge.swift` | Cross-cutting helpers: motion prefs, transitions, screen size |

---

## Theme Tokens (`SKTheme`)

```swift
enum SKTheme {
    // Palette — soft pastels
    static let cream     = UIColor(red: 0.98, green: 0.95, blue: 0.88, alpha: 1)
    static let sage      = UIColor(red: 0.78, green: 0.86, blue: 0.74, alpha: 1)
    static let dustyRose = UIColor(red: 0.93, green: 0.78, blue: 0.78, alpha: 1)
    static let sky       = UIColor(red: 0.78, green: 0.86, blue: 0.93, alpha: 1)
    static let cocoa     = UIColor(red: 0.42, green: 0.34, blue: 0.30, alpha: 1)
    static let gold      = UIColor(red: 0.96, green: 0.84, blue: 0.45, alpha: 1)

    // Fonts
    static func bodyFont(size: CGFloat) -> String
    static func headlineFont(size: CGFloat) -> String

    // Layout
    static let standardPadding: CGFloat = 16
    static let cardCornerRadius: CGFloat = 20
    static let minTouchTarget: CGFloat = 80

    // Animation
    static let standardTransitionDuration: TimeInterval = 0.28
    static let buttonPressDuration: TimeInterval = 0.10
}
```

**All UI code MUST reference `SKTheme` tokens. No raw hex colors or font
names at scene or component call sites.**

---

## `SKButton`

```swift
final class SKButton: SKNode {
    init(title: String, theme: SKButton.Theme = .primary, onTap: @escaping () -> Void)

    func setEnabled(_ enabled: Bool)
    func setTitle(_ title: String)
}

extension SKButton {
    enum Theme {
        case primary   // sage fill, cream text
        .secondary   // cocoa outline, cocoa text
        // .danger exists but is NOT used in bunny — soft palette only
    }
}
```

- Hit area padded to 80×80 minimum
- Tap → 100ms scale-down + scale-up (buttonPressDuration)
- Disabled state: 50% opacity, no tap response

---

## `SKHUD`

The HUD is the persistent overlay in gameplay scenes. It shows:

- The current instruction (top, large)
- A speaker icon to re-speak (top-right)
- Progress dots (bottom, one per interaction in the scene)
- An optional back button (top-left, only on hub scenes)

```swift
final class SKHUD: SKNode {
    init(instruction: String, totalSteps: Int)
    func markStepComplete(at index: Int)
    func setInstruction(_ text: String)
}
```

---

## `SKCard`

A rounded rectangle background with optional title and body labels.

```swift
final class SKCard: SKNode {
    init(size: CGSize, title: String? = nil, body: String? = nil)
}
```

Used for: reward screen container, parent dashboard panels, "Try it IRL"
card, achievement descriptions.

---

## `SKLayout`

Helpers that wrap common layout patterns:

```swift
enum SKLayout {
    static func center(_ node: SKNode, in parentSize: CGSize)
    static func pinToTop(_ node: SKNode, padding: CGFloat = SKTheme.standardPadding)
    static func pinToBottom(_ node: SKNode, padding: CGFloat = SKTheme.standardPadding)
    static func horizontalStack(_ nodes: [SKNode], spacing: CGFloat)
    static func verticalStack(_ nodes: [SKNode], spacing: CGFloat)
}
```

Scenes should prefer `SKLayout` helpers over manual `position` math.

---

## `SKBridge`

Cross-cutting helpers:

```swift
enum SKBridge {
    static func applyMotionPreferences(to scene: SKScene)
    static func transition(to route: SceneRouter.Route) -> SKTransition
    static func screenSize(for scene: SKScene) -> CGSize
    static func safeAreaInsets(for view: SKView) -> UIEdgeInsets
    static func announce(_ message: String)   // UIAccessibility announcement
}
```

---

## Source

- All files in `bunny iOS/UI/`

---

## Anti-Patterns

| Pattern | Why wrong |
|---|---|
| Hardcoded color literal in a scene | Breaks theming |
| Hardcoded font name in a scene | Breaks Dynamic Type |
| Custom transition in a scene | Use `SKBridge.transition(to:)` |
| Manual frame math instead of `SKLayout` | Inconsistent spacing |
| Touch target < 80×80 | Violates accessibility |
| Using `.red` or `.yellow` | Violates Pillar 1 (Calm) |

---

## Acceptance Criteria

- [ ] No hardcoded color outside `SKTheme` (enforced by code review)
- [ ] No hardcoded font name outside `SKTheme`
- [ ] All buttons use `SKButton`, not custom touch handlers
- [ ] All HUD elements use `SKHUD`
- [ ] All scene layouts use `SKLayout` helpers where applicable

---

## Open Questions

- Should we add a "dark mode" cream variant? Tracked for v2.

Last updated: 2026-01
