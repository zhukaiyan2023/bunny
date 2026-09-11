# SpriteKit Platform Notes (iOS / macOS / tvOS)

Last verified: 2026-01

The "bunny" project ships one SpriteKit codebase that builds into three native
targets. Most code is shared via target membership in `bunny.xcodeproj`. This
document captures the platform-specific differences that affect scene design.

## iOS (iPhone + iPad)

- **Frame**: `UIWindowScene` → `UIViewController` (`GameViewController`) → `SKView`
- **Touch**: `SKScene` exposes `touchesBegan/Moved/Ended` natively; multi-touch
  is **disabled** in `GameViewController.loadView()` (`isMultipleTouchEnabled = false`)
  to keep scene logic simple — one finger = one action.
- **Orientation**: Portrait only on iPhone; portrait + portrait-upside-down on
  iPad. `UISupportedInterfaceOrientations` enforces this.
- **Safe area**: `SKView` reads `view.safeAreaInsets`. HUD elements must respect
  top/bottom insets on iPhone X-class devices.
- **Status bar**: Hidden (`UIStatusBarHidden = true`) for an immersive feel.
- **Speech**: `SpeechService` uses `AVSpeechSynthesizer`; works on all iOS
  versions since 7.

## macOS

- **Frame**: `NSApplication` → `NSWindow` (storyboard) → `NSViewController` →
  `SKView` (UIKit-on-Mac bridging).
- **Input**: Mouse clicks → `mouseDown`/`mouseUp` (NOT `touchesBegan`). All
  shared scenes must therefore work through `SKScene` interactions that fall
  back to touch events when running on iOS. **Current limitation**: tap-only
  scenes work; drag scenes require mouse-driven fallback code.
- **Window**: Free-form resize. `GameViewController.viewWillTransition` is the
  iOS-only handler; macOS resizes are observed through `windowDidResize` (TODO).
- **Status bar**: macOS menu bar remains visible. Scenes should NOT rely on the
  top edge being tappable.

## tvOS

- **Frame**: `UIWindowScene` → `SceneDelegate` → `UIViewController` → `SKView`.
- **Focus engine**: Apple TV uses `UIFocusEnvironment` rather than touches.
  Scenes must explicitly support focus:
  - Set `isUserInteractionEnabled = false` on `SKSpriteNode` and use a focusable
    proxy instead (`UIView`-style focus interaction through the engine).
  - The top-level tvOS view controller is responsible for focus; SpriteKit
    nodes do not natively participate. (See ADR-0006 for our chosen approach.)
- **Siri Remote**: Touch surface swipes → `pressesBegan` (subtype `.select`)
  maps to "tap". The current scene factory does not yet bridge these.
- **Game loop**: `preferredFramesPerSecond = 60` matches TV refresh.

## Shared Targets

The `bunny Shared/` folder contains the cross-platform asset catalog
(`AppIcon`, `AccentColor`). Image assets specific to a target live in
`bunny iOS/Assets.xcassets/` and are added to other targets via Xcode membership.

## Cross-Platform Rules

1. **Scene code lives in `bunny iOS/Scenes/`** — it is added to all three
   targets via Xcode project membership. Do not duplicate scenes.
2. **No `#if os(...)` inside scene files**. Platform glue lives in each
   platform's `GameViewController.swift`. If a scene genuinely needs
   platform-specific behavior, route through a protocol.
3. **Use `SKTheme` for colors and fonts**, never hardcode hex/RGBA. The theme
   enum is shared across platforms.
4. **Touch OR focus — never both**. A scene designed for touch (iPhone/iPad)
   may not work as-is on tvOS. See ADR-0006.

## Open Questions

- Mouse drag fallback for macOS scene interactions (tracked in
  `production/qa/bugs/` once filed).
- tvOS focus proxy for in-scene `SKSpriteNode` selection — see ADR-0006.
