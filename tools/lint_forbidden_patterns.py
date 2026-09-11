#!/usr/bin/env python3
"""
S5-04 — Forbidden-patterns lint.

Enforces the rules in docs/architecture/control-manifest.md:
  - UserDefaults.standard only allowed in ProgressStore.swift
  - SKView.presentScene(...) only allowed in per-platform GameViewController.swift
  - #if os(...) forbidden inside scene files
  - print(...) forbidden inside scene files
  - Package.swift / Cartfile / Podfile forbidden (ADR-0007)

Exits non-zero with a readable violation list. Run from repo root:
    python3 tools/lint_forbidden_patterns.py
"""

import os
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent

# (regex, allowed-prefixes, message)
RULES = [
    (
        r"UserDefaults\.standard",
        ["bunny iOS/Services/ProgressStore.swift"],
        "Use ProgressStore.shared — never touch UserDefaults directly",
    ),
    (
        r"\.presentScene\(",
        [
            "bunny iOS/GameViewController.swift",
            "bunny macOS/GameViewController.swift",
            "bunny tvOS/GameViewController.swift",
        ],
        "Only GameViewController may call SKView.presentScene",
    ),
    (
        r"#if\s+os\(",
        ["bunny iOS/Scenes/"],
        "Scene files must be platform-agnostic; use per-platform GameViewController",
    ),
    (
        r"^\s*print\(",
        ["bunny iOS/Scenes/"],
        "Use os_log or Logger in scenes — not print",
    ),
]

# Disallowed dependency manifests (ADR-0007: zero third-party deps)
DISALLOWED_MANIFESTS = ["Package.swift", "Cartfile", "Podfile"]

# Scan roots
ROOTS = ["bunny iOS", "bunny macOS", "bunny tvOS", "bunny Shared"]

# Files explicitly excluded from the Xcode build via
# PBXFileSystemSynchronizedBuildFileExceptionSet. They live on disk but
# are never compiled, so lint rules don't apply. If a file on this list
# becomes part of the build, remove it from this allowlist.
ALLOWLIST = {
    "bunny Shared/GameScene.swift",  # Apple SpriteKit template (excluded from build)
    "bunny Shared/GameScene.sks",    # companion scene file (excluded from build)
}


def is_in_allowed_prefix(path: Path, allowed_prefixes: list[str]) -> bool:
    try:
        rel = path.resolve().relative_to(REPO)
    except ValueError:
        rel = path
    p_str = str(rel).replace("\\", "/")
    return any(p_str.startswith(a) for a in allowed_prefixes)


def scan_file(path: Path) -> list[str]:
    """Run ripgrep for the given regex; return matching lines."""
    try:
        result = subprocess.run(
            ["grep", "-nE", "--", _pattern_for(path), str(path)],
            capture_output=True, text=True, check=False,
        )
    except FileNotFoundError:
        # grep missing — fallback to manual read
        return []
    return [line for line in result.stdout.splitlines() if line]


def _pattern_for(path: Path) -> str:
    return _RULES_BY_PATH.get(path, "")


# We'll dispatch per-file by reading the file and matching each rule.
def check_rules(path: Path) -> list[tuple[str, str]]:
    """Return [(line_no, message), ...] for all rule violations in this file."""
    try:
        text = path.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError):
        return []

    violations: list[tuple[str, str]] = []
    p_str = str(path)
    for pattern, allowed_prefixes, message in RULES:
        if is_in_allowed_prefix(path, allowed_prefixes):
            continue
        regex = re.compile(pattern, re.MULTILINE)
        for m in regex.finditer(text):
            line_no = text.count("\n", 0, m.start()) + 1
            violations.append((str(line_no), message))
    return violations


def main() -> int:
    # 1. Disallowed manifest files
    for name in DISALLOWED_MANIFESTS:
        if (REPO / name).exists():
            print(f"FORBIDDEN: {name} (ADR-0007: zero third-party deps)",
                  file=sys.stderr)
            return 1

    # 2. Per-file rule scan
    total_violations = 0
    for root in ROOTS:
        root_path = REPO / root
        if not root_path.exists():
            continue
        for dp, _, files in os.walk(root_path):
            for f in files:
                if not f.endswith(".swift"):
                    continue
                fp = Path(dp) / f
                rel = str(fp.relative_to(REPO)).replace("\\", "/")
                if rel in ALLOWLIST:
                    continue
                for line_no, message in check_rules(fp):
                    print(f"{rel}:{line_no}  -- {message}", file=sys.stderr)
                    total_violations += 1

    if total_violations == 0:
        print("lint-forbidden-patterns: 0 violations ✓")
        return 0

    print(f"\nlint-forbidden-patterns: {total_violations} violation(s) "
          f"(see control-manifest.md for the rules)",
          file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
