# ADR-0007: Zero Third-Party Swift Dependencies

**Status**: Accepted
**Date**: 2026-01
**Deciders**: bunny team

---

## Context

bunny is a kids' edutainment app. Parents care about:
- Privacy (Pillar 4) — does the app track my child?
- Binary size — does it take up storage on the iPad?
- Reliability — does it crash?
- Longevity — will it still work in 5 years?

Every third-party dependency adds:
- Privacy surface (some SDKs harvest device IDs or behavioral data)
- Binary size (a dependency tree can easily add 5–20 MB)
- Reliability risk (a deprecated or abandoned SDK can break the app)
- Update burden (keeping dependencies current is a recurring task)

Apple's first-party frameworks cover everything bunny needs:
SpriteKit for rendering, AVFoundation for audio, Foundation for
persistence, UIKit for the host view controller.

---

## Decision

**bunny ships with zero third-party Swift dependencies.** Every
package added to the project requires an ADR.

`bunny.xcodeproj` has no `Package.swift` or `Cartfile` or `Podfile`.
The Xcode project's "Frameworks, Libraries, and Embedded Content"
section lists only Apple frameworks.

---

## Alternatives Considered

### A. Allow curated third-party deps via PR review
- **Pros**: flexibility when something is genuinely needed.
- **Cons**: easy to slip in questionable dependencies; pressure from
  "but this SDK would save us a week".
- **Why rejected**: an ADR is a higher bar that ensures the cost
  (privacy, size, maintenance) is explicitly considered.

### B. SPM-only deps (allow, but discourage)
- **Pros**: SPM is the modern way; curated by Apple.
- **Cons**: still has the privacy / size / maintenance costs.
- **Why rejected**: same as A.

### C. Allow internal-only packages (bunny's own split-out SPM modules)
- **Pros**: modularity, testability.
- **Cons**: SPM modules force public API boundaries; SpriteKit + UIKit
  don't play well with cross-module boundaries; unnecessary for v1 size.
- **Why rejected**: deferred to v2 if the codebase grows.

---

## Consequences

### Positive
- Tiny binary — bunny currently fits in < 10 MB
- Zero privacy surface from third-party SDKs
- No dependency upgrade cycle
- App works forever even if Apple deprecates a third-party SDK
- Easier App Store review (less supply-chain auditing)

### Negative
- We can't pull in a community library for a one-off problem
- Some features require writing more code ourselves (e.g., drag-and-drop
  on macOS — no third-party help)
- Slower iteration if the alternative is "just add a library"

### Neutral
- Apple frameworks (SpriteKit, AVFoundation, Foundation, UIKit, AppKit)
  are first-party and allowed — they are part of the platform
- Test dependencies (XCTest, swift-snapshot-testing) are first-party

---

## When to Revisit

A third-party dependency is acceptable IF:

- It is **privacy-clean** (no device IDs, no behavioral tracking, no analytics)
- It is **open-source** with a permissive license (MIT / Apache 2.0)
- It is **< 100 KB** binary contribution
- It is **actively maintained** (commits in the last 12 months)
- It is **necessary** (not just convenient — we could write it ourselves
  in < 200 lines)
- An ADR documents the decision

---

## Examples of DQs (would NOT pass)

- Firebase / Amplitude / Mixpanel — analytics, privacy violation
- AdMob / Unity Ads — ads, violates Pillar 4
- Lottie — nice-to-have, but we can do procedural animation for our needs
- SnapKit — UI layout, but we use SpriteKit + SKLayout
- Alamofire — networking, but we don't make network calls (Pillar 4)

---

## Examples of Possible Future Approvals

- A pure-data library like `swift-collections` — IF needed for a specific
  performance reason (currently no)
- A specific accessibility helper — IF the Apple API surface is
  genuinely insufficient (currently sufficient)

---

## References

- `design/gdd/platform-system.md`
- `design/gdd/persistence-system.md` (UserDefaults over third-party stores)
- `docs/architecture/overview.md` § 2 (Goals & Constraints)
- ADR-0003 (UserDefaults over Core Data)

Last updated: 2026-01
