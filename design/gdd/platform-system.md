# Platform System — GDD

**System slug**: SYS-FOUND-001
**Status**: Approved (v1.0)
**Pillars served**: All (cross-cutting)
**Last updated**: 2026-01

---

## Overview

The Platform System handles the differences between iOS, macOS, and tvOS.
bunny ships as a **single Xcode project with three targets**, sharing one
scene codebase via target membership. This document captures where
platform-specific code is allowed and what the boundary looks like.

---

## Requirements

| ID | Requirement |
|---|---|
| **TR-PLAT-001** | Each target MUST have its own `GameViewController` subclass. |
| **TR-PLAT-002** | Scene code in `bunny iOS/Scenes/` MUST be added to all three targets via Xcode project membership — no source duplication. |
| **TR-PLAT-003** | Scene code MUST compile unchanged for all three targets. |
| **TR-PLAT-004** | `#if os(...)` directives MUST NOT appear inside scene files. |
| **TR-PLAT-005** | Platform-specific behavior MUST be routed through a protocol or a per-platform `GameViewController`. |
| **TR-PLAT-006** | Touch handling in scenes MUST work on iOS and tvOS (via the focus proxy); macOS drag support is best-effort. |

---

## Per-Target Responsibilities

### `bunny iOS/`
- Hosts the SpriteKit view inside a `UIViewController`
- Handles touch events natively
- Orientation: portrait (iPhone), portrait + portrait-upside-down (iPad)
- Handles `viewWillTransition` to redraw at the new size
- `BunnyAppDelegate` sets up `AVAudioSession`
- `SceneDelegate` is the modern UIKit scene entry point

### `bunny macOS/`
- Hosts the SpriteKit view inside an `NSViewController` (UIKit-on-Mac bridge)
- Touch events arrive as mouse clicks; drag-based scenes need a fallback
- Window is freely resizable
- Menu bar visible

### `bunny tvOS/`
- Hosts the SpriteKit view inside a `UIViewController`
- Touch events arrive as Siri Remote swipes / presses
- **Focus engine integration** is the big piece — see ADR-0006
- Scene `touchesBegan` does NOT fire; focus proxy must be implemented

---

## Scene Sharing

The scene factory:

```swift
enum GameSceneFactory {
    static func makeScene(size: CGSize, level: LevelDefinition) -> SKScene {
        switch level.area {
        case .math:       return MathGameScene(size: size, level: level)
        case .english:    return EnglishGameScene(size: size, level: level)
        case .lifeSkills: return LifeSkillsGameScene(size: size, level: level)
        }
    }
}
```

This file is added to all three targets. The factory returns the same
`SKScene` subclass on every platform; the platform-specific
`GameViewController` is responsible for adapting input.

---

## tvOS Focus Proxy (deferred)

SpriteKit scenes do not natively participate in the tvOS focus engine.
A pragmatic v1 approach:

1. Add an invisible `UIView` overlay sized to the SKView
2. Use `UIFocusEnvironment` to highlight the currently focused in-scene element
3. Forward Siri Remote `.select` presses to the focused scene element

A focused, minimal implementation is tracked as a Sprint-3 story.

---

## Source

- `bunny iOS/GameViewController.swift`
- `bunny iOS/SceneDelegate.swift`
- `bunny iOS/App/BunnyAppDelegate.swift`
- `bunny macOS/GameViewController.swift`, `AppDelegate.swift`
- `bunny tvOS/GameViewController.swift`, `SceneDelegate.swift`, `AppDelegate.swift`

---

## Acceptance Criteria

- [ ] Building for iOS Simulator succeeds
- [ ] Building for macOS succeeds
- [ ] Building for tvOS Simulator succeeds
- [ ] No scene file uses `#if os(...)`
- [ ] All 14 scenes are members of all three targets in `bunny.xcodeproj`

---

## Open Questions

- tvOS focus proxy implementation (deferred to Sprint 3)
- macOS drag-fallback for scenes with drag interactions

Last updated: 2026-01
