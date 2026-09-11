# SpriteKit — Version Reference

| Field | Value |
|-------|-------|
| **Engine** | SpriteKit (`SpriteKit.framework`) |
| **Language** | Swift 5.0 |
| **iOS Deployment Target** | 26.5 |
| **macOS Deployment Target** | 26.5 |
| **tvOS Deployment Target** | 26.5 |
| **Xcode Version** | Xcode 26+ |
| **Project Pinned** | 2026-01 |
| **LLM Knowledge Cutoff** | January 2026 |
| **Risk Level** | LOW — SpriteKit API is stable across iOS 26.x; well within training data |
| **Last Verified** | 2026-01 |

## What is SpriteKit?

SpriteKit is Apple's native 2D game framework, bundled with the iOS / macOS / tvOS
SDK. It provides:

- `SKView` — a UIView / NSView subclass that hosts a SpriteKit scene graph
- `SKScene` — root container for nodes, manages the update loop
- `SKNode` — base class for all renderable objects (sprites, labels, shapes, emitters)
- Physics (`SKPhysicsBody`, `SKPhysicsWorld`)
- Actions (`SKAction` — tween, sequence, repeat)
- Texture atlases (`SKTextureAtlas`)
- Sound (`SKAudioNode`)
- Particle emitters (`SKEmitterNode`)
- Lighting (`SKLightNode`)
- Constraints and inverse kinematics

SpriteKit integrates with UIKit / AppKit on iOS / macOS and with TVMLKit on tvOS.
It shares the device's GPU compositor with `UIView`, allowing overlays such as
hud layers, alert panels, and parental gates.

## Why SpriteKit for "bunny"

| Reason | Notes |
|---|---|
| **Apple-native, zero install** | Ships with iOS / macOS / tvOS — no SDK to license or download |
| **Single-target, multi-platform** | Same Swift code paths can build for iPhone, iPad, Mac, and Apple TV |
| **Designed for 2D edutainment** | Built-in support for touch handling, gesture recognizers, child-friendly 2D physics |
| **Fast iteration** | Live in-process scene swaps via `SKView.presentScene(_:transition:)` |
| **Batteries included** | Built-in particle effects, shape nodes, label nodes — no external rendering layer |
| **Accessibility** | Inherits VoiceOver support from UIKit, no extra setup |

## API Status Snapshot

| API Area | Status in iOS 26.x | Notes |
|---|---|---|
| `SKView` / `SKScene` lifecycle | Stable | No changes since iOS 8 |
| Node tree (`SKNode` + children) | Stable | — |
| Actions (`SKAction`) | Stable | — |
| Physics (`SKPhysicsBody` / `SKPhysicsWorld`) | Stable | — |
| Texture atlases | Stable | Use `SKTextureAtlas(named:)` from bundle |
| Audio (`SKAudioNode`) | Stable | Prefer `AVAudioEngine` for advanced needs |
| Particle emitters | Stable | — |
| Lighting | Stable | `SKLightNode`, limited to normal-mapped sprites |
| Camera (`SKCameraNode`) | Stable | — |
| Constraints | Stable | Position / orientation / distance / reach constraints |
| Focus engine (tvOS) | Stable | `UIFocusEnvironment` integration via `allowsFocus` |

### APIs we explicitly rely on

| API | Used in | Notes |
|---|---|---|
| `SKView.presentScene(_:transition:)` | `GameViewController` | Drives all scene swaps |
| `SKTransition.fade(withDuration:)` | `GameViewController` | Default transition |
| `SKScene` subclassing | All 14 scenes | All scenes subclass `SKScene` directly |
| `SKTheme` (custom colors / fonts) | UI module | Static enums, no API risk |
| `SKSpriteNode` | UI + scene art | — |
| `SKLabelNode` | HUD, prompts | — |
| `SKShapeNode` | Progression rings, debug | — |
| NotificationCenter | `SceneRouter` → `GameViewController` | Cross-layer glue |
| `AVSpeechSynthesizer` | `SpeechService` | TTS for word pronunciation |
| `UserDefaults` | `ProgressStore` | Persistence |

### APIs we DO NOT use (and why)

| API | Reason |
|---|---|
| GameplayKit (`GKEntity` / `GKComponent`) | Overkill for hand-authored scenes; would add friction |
| Metal / custom shaders | SpriteKit covers all our 2D needs; no custom shaders planned |
| ARKit | 2D edutainment only |
| StoreKit | Single IAP not in current scope; gate via parental consent first |
| CoreData | `UserDefaults` + JSON (`levels.json`) is sufficient at this scale |

## Build & Run

```bash
# Build for iOS Simulator
xcodebuild -project bunny.xcodeproj \
  -scheme "bunny iOS" \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  build

# Build for macOS (Catalyst-style)
xcodebuild -project bunny.xcodeproj \
  -scheme "bunny macOS" \
  build

# Build for Apple TV Simulator
xcodebuild -project bunny.xcodeproj \
  -scheme "bunny tvOS" \
  -destination 'platform=tvOS Simulator,name=Apple TV' \
  build
```

## Updating the Engine Version

SpriteKit has no separate version number — its capabilities are tied to the host
OS. To upgrade:

1. Bump `IPHONEOS_DEPLOYMENT_TARGET` / `MACOSX_DEPLOYMENT_TARGET` / `TVOS_DEPLOYMENT_TARGET`
   in `bunny.xcodeproj/project.pbxproj`
2. Update the "iOS Deployment Target" / "Last Verified" rows above
3. Search Apple release notes for SpriteKit changes in the new version
4. If any used API is deprecated, file an issue and refactor in a separate PR
5. Re-run smoke tests on every target platform

## Reference Links

- [SpriteKit — Apple Developer](https://developer.apple.com/documentation/spritekit)
- [SKView — Apple Developer](https://developer.apple.com/documentation/spritekit/skview)
- [SKScene — Apple Developer](https://developer.apple.com/documentation/spritekit/skscene)
- [SKNode — Apple Developer](https://developer.apple.com/documentation/spritekit/sknode)
- [SKAction — Apple Developer](https://developer.apple.com/documentation/spritekit/skaction)
- [SpriteKit Programming Guide](https://developer.apple.com/library/archive/documentation/GraphicsAnimation/Conceptual/SpriteKit_PG/)
- [Apple Developer — iOS 26 Release Notes](https://developer.apple.com/documentation/ios-ipados-release-notes)

## Engine Reference Index

| File | Purpose |
|---|---|
| `VERSION.md` | This file — version pin and knowledge gap |
| `platform-notes.md` | Per-platform SpriteKit differences (iOS / macOS / tvOS) |
| `scene-lifecycle.md` | Scene initialization, transitions, teardown patterns |
| `performance-budgets.md` | 2D render budgets for kids' edutainment |
| `accessibility.md` | VoiceOver, Dynamic Type, Reduce Motion integration |

Last verified: 2026-01
