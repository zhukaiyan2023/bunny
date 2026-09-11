# ADR-0001: Pin SpriteKit on iOS 26.5 / Swift 5.0 as the Engine

**Status**: Accepted
**Date**: 2026-01
**Deciders**: bunny team

---

## Context

bunny is a 2D edutainment app for children ages 4–7 on Apple platforms.
We need a rendering + scene-graph engine that supports:

- 2D scene composition (background, sprites, labels, particles)
- Touch input
- Per-platform builds (iPhone, iPad, Mac, Apple TV) from one codebase
- Apple-native accessibility (VoiceOver, Dynamic Type, Reduce Motion)
- Zero third-party dependencies (Pillar 4)

The existing code is already built on Apple's SpriteKit (`SKView`,
`SKScene`, `SKSpriteNode`, `SKLabelNode`), with `AVSpeechSynthesizer`
for narration. The Xcode project sets `IPHONEOS_DEPLOYMENT_TARGET = 26.5`,
`SWIFT_VERSION = 5.0`.

---

## Decision

**Use Apple's SpriteKit as the engine**, pinned to the iOS 26.5 / Swift
5.0 surface. No third-party game engine. No custom Metal layer. No
SceneKit (3D not needed).

The engine reference is `docs/engine-reference/spritekit/VERSION.md`.

---

## Alternatives Considered

### A. Unity
- **Pros**: massive 2D/3D ecosystem, great tooling, Asset Store, child-friendly examples.
- **Cons**: adds 200+ MB to the binary; violates "zero third-party dependencies"; C# skill set not in use; ~$400/year Pro license once revenue crosses $200K.
- **Why rejected**: violates Pillar 4 (we want a tiny, auditable binary) and the existing codebase is already in SpriteKit.

### B. Godot
- **Pros**: open source, lightweight, GDScript or C#.
- **Cons**: console exports require third-party publisher; macOS / iOS workflows less mature; existing codebase is SpriteKit.
- **Why rejected**: would require rewriting all 36 Swift files; no benefit over SpriteKit for this scope.

### C. UIKit-only (no SpriteKit)
- **Pros**: smallest binary, no abstraction layer.
- **Cons**: scene graph, particles, actions, physics all hand-rolled; significantly more code; harder accessibility.
- **Why rejected**: SpriteKit's scene graph is the right level of abstraction for 50 hand-authored scenes.

### D. SwiftUI + Canvas
- **Pros**: pure SwiftUI, declarative.
- **Cons**: imperative animation is awkward; scene graph is missing; Apple TV focus integration is rough; existing code is SpriteKit.
- **Why rejected**: not a good fit for game-loop scenes.

---

## Consequences

### Positive
- Small binary (SpriteKit is built into iOS)
- Full Apple accessibility support (VoiceOver, Dynamic Type, Reduce Motion) for free
- One codebase, three platforms via Xcode targets
- No external SDK upgrades to track
- All existing 36 Swift files continue to work

### Negative
- tvOS focus engine requires a custom proxy (see ADR-0006)
- No custom Metal shaders (mitigated — none needed for v1)
- Locked to Apple platforms (acceptable — that is the target audience)

### Neutral
- Swift 5.0 is the language level; Swift 6 concurrency is available but
  not adopted (single-threaded gameplay in v1).

---

## References

- `docs/engine-reference/spritekit/VERSION.md`
- `docs/engine-reference/spritekit/scene-lifecycle.md`
- `docs/engine-reference/spritekit/performance-budgets.md`

Last updated: 2026-01
