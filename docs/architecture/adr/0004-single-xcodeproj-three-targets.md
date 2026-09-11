# ADR-0004: Single Xcode Project, Three Targets, Shared Scene Code

**Status**: Accepted
**Date**: 2026-01
**Deciders**: bunny team

---

## Context

bunny needs to ship to:
- **iPhone + iPad** (iOS / iPadOS)
- **Mac** (macOS, via UIKit-on-Mac bridging)
- **Apple TV** (tvOS)

The codebase has ~36 Swift files, 14 scenes, and shared assets. We need
a project structure that:

- Avoids source duplication
- Lets each platform have its own `Info.plist`, storyboard, and
  `GameViewController` shim
- Allows per-platform conditional code where genuinely needed
- Is straightforward to open in Xcode and build

---

## Decision

**One Xcode project (`bunny.xcodeproj`) with three targets**:

- `bunny iOS` — full source tree, all scenes, UIKit host
- `bunny macOS` — thin shim (`AppDelegate`, `GameViewController`, storyboard)
- `bunny tvOS` — thin shim (`AppDelegate`, `SceneDelegate`, `GameViewController`, storyboard, `Info.plist`)

Scene code, UI primitives, models, and services are added to all three
targets via Xcode project membership. Platform-specific files live only
in their target's folder.

### File Layout

```
bunny.xcodeproj/
bunny Shared/        # AppIcon + AccentColor (cross-platform assets)
bunny iOS/           # most code (App, Scenes, UI, Models, Services)
bunny macOS/         # macOS-only shim
bunny tvOS/          # tvOS-only shim
```

---

## Alternatives Considered

### A. Separate Xcode projects per platform
- **Pros**: total isolation.
- **Cons**: scene code must be copied or added as a framework; merges painful; build configs diverge.
- **Why rejected**: Apple ships this template; works well for our scope.

### B. Swift Package + three thin executables
- **Pros**: SPM-native, modular.
- **Cons**: SpriteKit and UIKit aren't great as SPM modules; would force a different folder layout; asset catalogs don't fit SPM cleanly.
- **Why rejected**: too much disruption for no benefit.

### C. Cross-platform framework (shared scenes as a framework)
- **Pros**: clean module boundary.
- **Cons**: adds a build step; SpriteKit + UIKit code in a framework has its own pitfalls; overkill for v1.
- **Why rejected**: deferred to v2 if the codebase grows.

### D. Catalyst only (iPad app running on Mac)
- **Pros**: one binary, no macOS target.
- **Cons**: leaves out a real macOS app; tvOS would still need a separate target.
- **Why rejected**: we want a real Mac app, not just an iPad-on-Mac experience.

---

## Consequences

### Positive
- Zero source duplication for scenes, UI, models, services
- Each platform keeps its own `Info.plist`, storyboard, and host
  `GameViewController`
- Single Xcode workspace; one repo, one build command
- Matches Apple's default SpriteKit template — familiar to iOS devs

### Negative
- Scene files MUST be platform-agnostic (no `#if os(...)` inside scenes)
- Test target needs to be added carefully to the right platforms
- Asset catalogs are not auto-shared — need manual project membership

### Neutral
- Platform-specific code lives in `bunny <platform>/` folders
- The "shared" layer is implicit (target membership), not a separate folder

---

## Adding a New Platform

If we ever add a new platform (e.g., visionOS):

1. Create `bunny visionOS/` folder with `GameViewController`, storyboard, `Info.plist`
2. Add scenes, UI, models, services to the new target via Xcode membership
3. Document any platform-specific differences in
   `docs/engine-reference/spritekit/platform-notes.md`

---

## References

- `bunny.xcodeproj/project.pbxproj`
- `docs/architecture/overview.md` § 6.3 (File Organization)
- `design/gdd/platform-system.md`

Last updated: 2026-01
