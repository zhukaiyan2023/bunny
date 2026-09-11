# Story S5-03 — `levels.json` Schema Validator in CI

**Epic**: EPIC-005 — CI, Test Infrastructure, Release Pipeline
**Status**: Ready (depends on S5-01)
**GDD req**: TR-CURR-004
**ADR**: ADR-0005 (curriculum as JSON)
**Story type**: Infrastructure
**Acceptance test**: corrupted `levels.json` makes CI fail

---

## Context

`bunny iOS/Resources/levels.json` is the source of truth for all 50
levels. A typo in a JSON file or a missing field silently corrupts the
game. We need a script that validates the JSON against the documented
schema and runs in CI on every PR.

---

## Acceptance Criteria

- [ ] `tools/validate-levels-json.py` exists (Python 3 script)
- [ ] Script verifies:
  - Top-level array with exactly 50 entries
  - Each entry has: `id`, `area`, `title`, `scene`, `instruction`,
    `vocabulary`, `difficulty`
  - `id` matches `^[MEL][0-9]{2}$`
  - `area` ∈ {`Math`, `English`, `Life Skills`}
  - `difficulty` ∈ {1, 2, 3, 4, 5}
  - `vocabulary` is a non-empty array of non-empty strings
  - All `id`s are unique
  - Areas sum to 25 Math + 15 English + 10 Life Skills
- [ ] Script exits non-zero with a clear error message on failure
- [ ] Script is wired into `.github/workflows/ci.yml` as a separate job
  (`validate-levels`)
- [ ] Introducing an invalid entry makes CI fail with a readable error

---

## Implementation Notes

```python
# tools/validate-levels-json.py
import json, re, sys

REQUIRED = {"id","area","title","scene","instruction","vocabulary","difficulty"}
AREAS = {"Math", "English", "Life Skills"}

def main():
    with open("bunny iOS/Resources/levels.json") as f:
        data = json.load(f)
    assert len(data) == 50, f"expected 50 levels, got {len(data)}"
    seen = set()
    counts = {"Math":0,"English":0,"Life Skills":0}
    for lv in data:
        assert REQUIRED.issubset(lv.keys()), f"missing fields in {lv.get('id','?')}"
        assert re.match(r"^[MEL]\d{2}$", lv["id"]), f"bad id {lv['id']}"
        assert lv["area"] in AREAS, f"bad area {lv['area']}"
        assert lv["difficulty"] in {1,2,3,4,5}, f"bad difficulty {lv['difficulty']}"
        assert isinstance(lv["vocabulary"], list) and lv["vocabulary"], f"empty vocab in {lv['id']}"
        assert all(isinstance(w,str) and w for w in lv["vocabulary"]), f"empty word in {lv['id']}"
        assert lv["id"] not in seen, f"dup id {lv['id']}"
        seen.add(lv["id"])
        counts[lv["area"]] += 1
    assert counts == {"Math":25,"English":15,"Life Skills":10}, counts
    print("levels.json validates ✓")

if __name__ == "__main__":
    try: main()
    except AssertionError as e:
        print(f"FAIL: {e}", file=sys.stderr)
        sys.exit(1)
```

---

## Engine Risk

**None** — pure data validation.

---

## Test Evidence Path

A test JSON file in `tools/fixtures/levels-bad-*.json` proves the
script rejects malformed input.
