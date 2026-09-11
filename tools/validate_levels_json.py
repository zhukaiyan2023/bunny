#!/usr/bin/env python3
"""
S5-03 — levels.json schema validator.

Validates bunny iOS/Resources/levels.json against the documented schema
in design/gdd/curriculum-system.md. Exits non-zero with a readable error
on any violation.

Run from repo root:  python3 tools/validate_levels_json.py
"""

import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
LEVELS_JSON = REPO / "bunny iOS" / "Resources" / "levels.json"

REQUIRED_FIELDS = {"id", "area", "title", "scene", "instruction",
                   "vocabulary", "difficulty"}
VALID_AREAS = {"Math", "English", "Life Skills"}
EXPECTED_COUNTS = {"Math": 25, "English": 15, "Life Skills": 10}
ID_PATTERN = re.compile(r"^[MEL]\d{2}$")
VALID_DIFFICULTIES = {1, 2, 3, 4, 5}


def fail(msg: str) -> None:
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(1)


def main() -> None:
    if not LEVELS_JSON.exists():
        fail(f"missing levels file: {LEVELS_JSON}")

    try:
        with LEVELS_JSON.open(encoding="utf-8") as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        fail(f"malformed JSON in {LEVELS_JSON.name}: {e}")

    if not isinstance(data, list):
        fail(f"{LEVELS_JSON.name}: expected top-level array, got {type(data).__name__}")

    total = len(data)
    if total != 50:
        fail(f"{LEVELS_JSON.name}: expected exactly 50 levels, found {total}")

    seen_ids: set[str] = set()
    area_counts: dict[str, int] = {a: 0 for a in VALID_AREAS}

    for idx, lv in enumerate(data):
        if not isinstance(lv, dict):
            fail(f"level #{idx}: not an object")

        missing = REQUIRED_FIELDS - lv.keys()
        if missing:
            fail(f"level #{idx}: missing fields {sorted(missing)}")

        lv_id = lv["id"]
        if not isinstance(lv_id, str) or not ID_PATTERN.match(lv_id):
            fail(f"level #{idx}: bad id {lv_id!r} (must match [MEL]<NN>)")

        if lv_id in seen_ids:
            fail(f"level #{idx}: duplicate id {lv_id!r}")
        seen_ids.add(lv_id)

        area = lv["area"]
        if area not in VALID_AREAS:
            fail(f"level {lv_id}: bad area {area!r} (must be one of {sorted(VALID_AREAS)})")
        area_counts[area] += 1

        title = lv["title"]
        if not isinstance(title, str) or not title.strip():
            fail(f"level {lv_id}: empty title")

        scene = lv["scene"]
        if not isinstance(scene, str) or not scene.strip():
            fail(f"level {lv_id}: empty scene kind")

        instruction = lv["instruction"]
        if not isinstance(instruction, str) or not instruction.strip():
            fail(f"level {lv_id}: empty instruction")

        vocab = lv["vocabulary"]
        if not isinstance(vocab, list) or not vocab:
            fail(f"level {lv_id}: vocabulary must be a non-empty array")
        if not all(isinstance(w, str) and w.strip() for w in vocab):
            fail(f"level {lv_id}: vocabulary contains empty/non-string word")

        diff = lv["difficulty"]
        if diff not in VALID_DIFFICULTIES:
            fail(f"level {lv_id}: difficulty {diff!r} not in {sorted(VALID_DIFFICULTIES)}")

    if area_counts != EXPECTED_COUNTS:
        fail(f"area counts {area_counts} != expected {EXPECTED_COUNTS}")

    print(f"levels.json validates ✓ ({total} levels, "
          f"{area_counts['Math']} Math + {area_counts['English']} English + "
          f"{area_counts['Life Skills']} Life Skills)")


if __name__ == "__main__":
    main()
