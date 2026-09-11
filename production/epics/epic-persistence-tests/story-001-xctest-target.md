# Story S2-01 — Add `bunnyTests` XCTest Target

**Epic**: EPIC-002 — Persistence Hardening + Unit Test Coverage
**Status**: Ready
**GDD req**: n/a (infrastructure)
**ADR**: ADR-0004 (single project, three targets)
**Story type**: Infrastructure
**Acceptance test**: the test target builds and an empty XCTest passes

---

## Context

bunny has no test target. Adding unit tests for `ProgressStore`,
`Curriculum`, and `SceneRouter` requires a test target inside
`bunny.xcodeproj`. This story adds the bare target so subsequent
stories (S2-02..04) can add test classes to it.

---

## Acceptance Criteria

- [ ] `bunnyTests` target exists in `bunny.xcodeproj`
- [ ] Target type: iOS Unit Testing Bundle (added to iOS target only)
- [ ] Target membership: `bunny iOS/*.swift` source files are visible
  to `bunnyTests` (test can `@testable import bunny_iOS` or similar)
- [ ] One trivial smoke test (e.g., `XCTestCase.tearDown`) compiles and passes
- [ ] `xcodebuild test -scheme "bunny iOS" -destination 'platform=iOS Simulator,name=iPhone 15'`
  succeeds and reports 1 test passed
- [ ] The test target is added to CI in S5-02

---

## Implementation Notes

Manually edit `bunny.xcodeproj/project.pbxproj` to add:
- A new target `bunnyTests` (PBXNativeTarget, productType
  `com.apple.product-type.bundle.unit-test`)
- A build configuration list (Debug + Release)
- A test runner host = `bunny iOS`
- A single `bunnyTests.swift` with an empty `XCTestCase` subclass

Alternatively, use the `xcodeproj` Ruby gem to script the addition.

```swift
// bunny iOS/Tests/bunnyTests.swift
import XCTest
@testable import bunny_iOS

final class bunnyTests: XCTestCase {
    func test_smoke() {
        XCTAssertTrue(true)
    }
}
```

---

## Engine Risk

**Low** — Xcode project surgery is delicate but reversible.

---

## Test Evidence Path

`xcodebuild test` output shows the target name + 1 test passed.
