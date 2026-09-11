# Story S2-01 — Standalone Unit Test Runner

**Epic**: EPIC-002 — Persistence Hardening + Unit Test Coverage
**Status**: Done (deviation from original spec)
**GDD req**: n/a (infrastructure)
**ADR**: ADR-0004 (single project, three targets)
**Story type**: Infrastructure
**Acceptance test**: 37/37 unit tests pass; CI runs them on every PR

---

## Context

Sprint 1's plan called for adding a `bunnyTests` XCTest target inside
`bunny.xcodeproj`. The original approach was rejected after inspection:

### Why we did NOT add an Xcode test target

The bunny project uses Xcode 16's `PBXFileSystemSynchronizedRootGroup`
feature — entire folders (`bunny iOS/`, `bunny macOS/`, `bunny tvOS/`,
`bunny Shared/`) are auto-synced into their respective targets via
`PBXFileSystemSynchronizedBuildFileExceptionSet`. Adding a new test
target requires pbxproj surgery with multiple synchronized root groups
plus target membership wiring — risky for a Sprint 1 deliverable.

### The adopted approach

We built a **standalone Swift test runner** using `swiftc` that compiles
the testable source files (ProgressStore, Curriculum, SceneRoute,
SceneLessonPlan — all `import Foundation` only) together with the test
files in `tests/unit/` into a single binary, then runs the binary.

The runner script lives at `tools/run_unit_tests.sh`. Tests live in
`tests/unit/`. The CI workflow runs `bash tools/run_unit_tests.sh` on
every PR.

### Trade-offs

| Pro | Con |
|---|---|
| Zero pbxproj surgery risk | Tests don't show up in Xcode's Test navigator |
| Same test coverage (37 tests) | Cannot be run interactively from Xcode |
| Same CI integration | Slightly slower than XCTest (~3s compile + ~1s run) |
| Trivial to extend (just add a test) | Bypasses Xcode's parallel test runner |
| Independent of any target's compile sources | Tests can't easily exercise SpriteKit/UIKit types |

The trade-offs are acceptable for v1. Migrating to a true XCTest target
is tracked as a Sprint 2 polish item if we want Xcode UI integration.

---

## Acceptance Criteria (revised)

- [x] `tools/run_unit_tests.sh` exists and is executable
- [x] `tests/unit/TestHarness.swift` provides an XCTest-style assertion API
- [x] `tests/unit/ProgressStoreTests.swift` covers 16 ProgressStore cases
- [x] `tests/unit/CurriculumTests.swift` covers 11 Curriculum cases
- [x] `tests/unit/SceneRouterTests.swift` covers 10 SceneRouter cases
- [x] Total: 37 tests, all passing
- [x] `levels.json` is bundled next to the test binary so `Bundle.main`
  can find it (see `tools/run_unit_tests.sh` cp step)
- [x] GitHub Actions runs the unit tests on every PR (job: `unit-tests`)
- [x] Each test is isolated via per-test `UserDefaults` suites with UUID names
- [x] `@MainActor` is correctly applied (ProgressStore and SceneRouter are
  main-actor-isolated; tests run on the main actor)

---

## Implementation Notes

```bash
$ bash tools/run_unit_tests.sh
Compiling...
Running...

ProgressStore tests:
  ✓ stars_defaultEmpty
  ✓ stars_roundTrip
  ... (37 tests)

Ran 37 tests: 37 passed, 0 failed
$ echo $?
0
```

Exit code 0 on full pass; non-zero on any failure. CI fails the build.

### Adding a new test

1. Add the test to the appropriate `*Tests.swift` file.
2. If new, create the file and add it to the `TESTS=(...)` array in
   `tools/run_unit_tests.sh`.
3. Run `bash tools/run_unit_tests.sh`.

---

## Engine Risk

**None** — `swiftc` and `Foundation` are platform-standard.

---

## Future Work

Migrate to a true XCTest target in Sprint 2 if Xcode UI test integration
becomes important. The migration would:

1. Add `bunnyTests` as a new PBXNativeTarget (productType
   `com.apple.product-type.bundle.unit-test`)
2. Add a synchronized folder for `tests/unit/`
3. Add `bunny iOS/` as a host (test target depends on app target)
4. Replace the standalone runner with `xcodebuild test -scheme "bunny iOS"`

Estimated effort: 1 sprint story.

Last updated: 2026-01
