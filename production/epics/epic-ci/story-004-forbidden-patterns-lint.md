# Story S5-04 — Forbidden-Patterns Lint

**Epic**: EPIC-005 — CI, Test Infrastructure, Release Pipeline
**Status**: Ready (depends on S5-01)
**GDD req**: n/a (control-manifest enforcement)
**ADRs**: ADR-0002, ADR-0003, ADR-0004, ADR-0007
**Story type**: Infrastructure
**Acceptance test**: introducing a forbidden pattern fails CI

---

## Context

The `control-manifest.md` enumerates patterns that MUST NEVER appear in
the bunny codebase (direct `UserDefaults` access outside `ProgressStore`,
`SKView.presentScene` outside `GameViewController`, `#if os(...)` inside
scenes, third-party SPM deps, etc.). Today these rules are enforced only
by code review — easy to miss. We need an automated lint that runs in
CI and fails the build on violations.

---

## Acceptance Criteria

- [ ] `tools/lint-forbidden-patterns.py` exists
- [ ] The script greps for the forbidden patterns and reports each
  violation with file path and line number
- [ ] Forbidden patterns include (at minimum):
  - `UserDefaults.standard` outside `bunny iOS/Services/ProgressStore.swift`
  - `SKView` `presentScene` outside `bunny iOS/GameViewController.swift`,
    `bunny macOS/GameViewController.swift`, `bunny tvOS/GameViewController.swift`
  - `#if os(` inside `bunny iOS/Scenes/`
  - Existence of `Package.swift`, `Cartfile`, `Podfile` (ADR-0007)
  - `print(` in `bunny iOS/Scenes/`
- [ ] Script exits non-zero if any violation is found
- [ ] Script is wired into CI as a separate job (`lint`)
- [ ] Running the script against the current `main` produces **zero**
  violations
- [ ] Introducing a violation (e.g., adding `UserDefaults.standard` in a
  scene) makes CI fail

---

## Implementation Notes

```python
# tools/lint-forbidden-patterns.py (sketch)
import os, re, sys, subprocess

VIOLATIONS = [
    (r"UserDefaults\.standard",
     ["bunny iOS/Services/ProgressStore.swift"],
     "Use ProgressStore — never touch UserDefaults directly"),
    (r"\.presentScene\(",
     ["bunny iOS/GameViewController.swift",
      "bunny macOS/GameViewController.swift",
      "bunny tvOS/GameViewController.swift"],
     "Only GameViewController may call presentScene"),
    (r"#if\s+os\(",
     ["bunny iOS/Scenes/"],
     "Scene files must be platform-agnostic; use per-platform GameViewController"),
    (r"^\s*print\(",
     ["bunny iOS/Scenes/"],
     "Use os_log or Logger, not print"),
]

# Disallowed dependency manifests
for f in ("Package.swift", "Cartfile", "Podfile"):
    if os.path.exists(f):
        print(f"FORBIDDEN: {f} (ADR-0007: zero third-party deps)", file=sys.stderr)
        sys.exit(1)

def matches(path, pattern):
    return subprocess.run(["grep","-nE",pattern,path],
                          capture_output=True, text=True).stdout

fail = False
for pat, allowed, msg in VIOLATIONS:
    for root in ["bunny iOS","bunny macOS","bunny tvOS","bunny Shared"]:
        for dp, _, files in os.walk(root):
            if any(dp.startswith(a) for a in allowed): continue
            for f in files:
                if not f.endswith(".swift"): continue
                p = os.path.join(dp, f)
                out = matches(p, pat)
                if out:
                    for line in out.splitlines():
                        print(f"{p}:{line}  -- {msg}", file=sys.stderr)
                        fail = True

sys.exit(1 if fail else 0)
```

---

## Engine Risk

**None** — pure static analysis.

---

## Out of Scope

- Auto-fix capability (deferred — script only reports)
- SwiftLint (may add later for style checks; this script handles
  semantic rules)

---

## Test Evidence Path

CI run log + a fixture file in `tools/fixtures/lint-bad-*.swift` that
the script correctly flags.
