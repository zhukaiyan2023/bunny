# ADR-0006: tvOS Focus Engine via UIFocusEnvironment Proxy

**Status**: Accepted (implementation deferred to Sprint 3)
**Date**: 2026-01
**Deciders**: bunny team

---

## Context

Apple TV (tvOS) uses the `UIFocusEnvironment` focus engine for input,
not raw touches. SpriteKit scenes do **not** natively participate in
focus — `touchesBegan` does not fire from the Siri Remote. A scene
designed for touch (iPhone / iPad) would be unusable on Apple TV
without adaptation.

The v1 launch target is iPhone / iPad / Mac. tvOS support is on the
roadmap but not required for the first App Store submission.

---

## Decision

**Defer tvOS support to a post-launch sprint.** When implemented, use
a `UIFocusEnvironment` proxy layered over the SKView:

1. Add an invisible `UIView` overlay sized to the SKView
2. Use `UIFocusEnvironment` to highlight the currently focused in-scene element
3. Forward Siri Remote `.select` presses to the focused scene element
4. Handle D-pad navigation by highlighting the next focusable in-scene element

The scene code itself stays platform-agnostic (per ADR-0004); only the
tvOS `GameViewController` adds the focus proxy.

For v1, the tvOS target builds but is not part of the App Store
submission.

---

## Alternatives Considered

### A. Rewrite scenes to be focus-native
- **Pros**: cleanest tvOS experience.
- **Cons**: doubles the scene codebase; violates "zero source duplication".
- **Why rejected**: too costly for the audience size.

### B. Skip tvOS entirely (2 targets only)
- **Pros**: simplest.
- **Cons**: loses Apple TV reach.
- **Why rejected**: we plan to ship to Apple TV eventually.

### C. Use a UIKit overlay with focus-aware buttons instead of in-scene SKNodes
- **Pros**: leverages Apple's focus engine directly.
- **Cons**: visuals would diverge from iOS / iPadOS; defeats the purpose of "shared scene code".
- **Why rejected**: would create two visual experiences.

### D. Third-party library (e.g., FocusEngine)
- **Pros**: ready-made.
- **Cons**: violates ADR-0007 (zero third-party dependencies).
- **Why rejected**: zero deps is the rule.

---

## Consequences

### Positive
- One scene codebase stays platform-agnostic (preserves ADR-0004)
- tvOS support arrives without rewriting scenes
- The proxy lives entirely in `bunny tvOS/GameViewController.swift`

### Negative
- tvOS launch is delayed past v1.0
- Focus highlighting won't match the in-scene sprite animation perfectly
- Significant engineering work deferred

### Neutral
- The `bunny tvOS` target builds successfully today but is not exercised
  by QA until the proxy lands

---

## Implementation Outline (Sprint 3)

```swift
// bunny tvOS/GameViewController.swift

import UIKit
import SpriteKit

final class GameViewController: UIViewController {
    private let host = SKView(frame: .zero)
    private let focusProxy = SKFocusProxy()  // NEW: custom focus overlay

    override func loadView() {
        // ... existing host setup ...
        view.addSubview(focusProxy)
        focusProxy.translatesAutoresizingMaskIntoConstraintsIntoSubtree = false
        focusProxy.focusableNodesProvider = { [weak self] in
            self?.currentFocusableNodes() ?? []
        }
    }
}
```

Implementation tracked as `S3-T08-tvos-focus-proxy` story.

---

## References

- `design/gdd/platform-system.md`
- `bunny tvOS/GameViewController.swift`
- ADR-0004 (single project, three targets)
- ADR-0007 (zero third-party deps)

Last updated: 2026-01
