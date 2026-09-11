# Story S5-01 — GitHub Actions: Build All 3 Targets

**Epic**: EPIC-005 — CI, Test Infrastructure, Release Pipeline
**Status**: Ready
**GDD req**: n/a (infrastructure)
**ADR**: ADR-0004 (single project, three targets)
**Story type**: Infrastructure
**Acceptance test**: PR trigger runs the workflow successfully

---

## Context

The bunny project is a single Xcode project with three targets
(`bunny iOS`, `bunny macOS`, `bunny tvOS`). Currently there is no CI:
every developer builds locally, and bugs only surface when another dev
tries to build. We need a GitHub Actions workflow that builds all three
targets on every PR so regressions are caught before merge.

---

## Acceptance Criteria

- [ ] `.github/workflows/ci.yml` exists
- [ ] Workflow triggers on `pull_request` and `push` to `main`
- [ ] Workflow runs on `macos-14` (Apple Silicon runner)
- [ ] Workflow checks out the repo, then runs `xcodebuild build` for each of:
  - `bunny iOS` (destination: iOS Simulator)
  - `bunny macOS` (destination: macOS)
  - `bunny tvOS` (destination: tvOS Simulator)
- [ ] All three builds succeed for the current `main`
- [ ] PR shows a green CI status before merge
- [ ] Workflow YAML is reusable via `workflow_call` (so future stories
  like S5-02 can extend it)

---

## Implementation Notes

```yaml
# .github/workflows/ci.yml
name: CI
on:
  pull_request:
  push:
    branches: [main]
jobs:
  build:
    runs-on: macos-14
    strategy:
      matrix:
        target: ["bunny iOS", "bunny macOS", "bunny tvOS"]
    steps:
      - uses: actions/checkout@v4
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_26.app
      - name: Build ${{ matrix.target }}
        run: |
          xcodebuild \
            -project bunny.xcodeproj \
            -scheme "${{ matrix.target }}" \
            -destination 'generic/platform=iOS Simulator' \
            build
```

The exact destinations may need tuning; a minimal smoke build (no
archive) is sufficient for v1.

---

## Engine Risk

**None** — pure CI infrastructure.

---

## Out of Scope

- Running XCTest in CI (tracked as S5-02, depends on S2-01)
- TestFlight upload (post-launch)

---

## Test Evidence Path

`.github/workflows/ci.yml` run history on the `Actions` tab.

`production/qa/bugs/` will contain any build-break issues found.
