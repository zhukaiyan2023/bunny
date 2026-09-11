#!/usr/bin/env bash
# S2-02..04 — Standalone unit test runner.
#
# Compiles the testable model/service Swift files together with the test
# files in tests/unit/, then runs the resulting binary. Exits non-zero on
# any test failure.
#
# Why not an Xcode test target? The bunny Xcode project uses Xcode 16's
# PBXFileSystemSynchronizedRootGroup feature, which auto-syncs whole
# folders into targets. Adding a new test target requires pbxproj surgery
# with multiple synchronized root groups + target membership — risky and
# out of scope for Sprint 1.
#
# These four source files only import Foundation, so they're trivially
# compilable with `swiftc` and runnable as a standalone binary.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

OUT=/tmp/bunny_unit_tests
OUT_DIR="$(dirname "$OUT")"
SOURCES=(
    "bunny iOS/Services/ProgressStore.swift"
    "bunny iOS/Models/Curriculum.swift"
    "bunny iOS/Models/SceneRoute.swift"
    "bunny iOS/Models/SceneLessonPlan.swift"
)
TESTS=(
    "tests/unit/TestHarness.swift"
    "tests/unit/ProgressStoreTests.swift"
    "tests/unit/CurriculumTests.swift"
    "tests/unit/SceneRouterTests.swift"
    "tests/unit/TestEntry.swift"
)

# Curriculum.swift loads `levels.json` via Bundle.main. For a CLI binary,
# Bundle.main is the directory containing the executable, so we copy the
# resource next to the test binary before running.
LEVELS_JSON_SRC="bunny iOS/Resources/levels.json"
LEVELS_JSON_DEST="$OUT_DIR/levels.json"

# Require a recent Swift toolchain (Xcode 26 ships Swift 6).
if ! command -v swiftc >/dev/null; then
    echo "FAIL: swiftc not on PATH" >&2
    exit 1
fi

echo "Compiling..."
if ! swiftc \
    -parse-as-library \
    -o "$OUT" \
    "${SOURCES[@]}" \
    "${TESTS[@]}"; then
    echo "FAIL: swiftc compilation failed" >&2
    exit 1
fi

# Bundle levels.json next to the test binary so Bundle.main finds it.
cp "$LEVELS_JSON_SRC" "$LEVELS_JSON_DEST"

echo "Running..."
echo ""
"$OUT"
