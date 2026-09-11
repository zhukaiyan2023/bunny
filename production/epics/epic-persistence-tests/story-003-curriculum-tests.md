# Story S2-03 — Curriculum JSON Decode + Fallback Tests

**Epic**: EPIC-002 — Persistence Hardening + Unit Test Coverage
**Status**: Ready (depends on S2-01)
**GDD req**: TR-CURR-001..005
**ADR**: ADR-0005 (curriculum as JSON)
**Story type**: Test
**Acceptance test**: all tests pass in CI

---

## Context

`Curriculum` loads 50 levels from `levels.json`. The loading must
succeed for the bundled file and must gracefully fall back to a single
hardcoded level if the JSON is missing or malformed. Today this is
unverified — a regression could silently leave the game with 1 level.

---

## Acceptance Criteria

- [ ] `tests/unit/CurriculumTests.swift` exists in the `bunnyTests`
  target
- [ ] Test cases:

| Test | Description |
|---|---|
| `test_loadsAllFiftyLevels` | With bundled `levels.json`, `Curriculum.levels.count == 50` |
| `test_levelsInMath` | `Curriculum.levels(in: .math).count == 25` |
| `test_levelsInEnglish` | `Curriculum.levels(in: .english).count == 15` |
| `test_levelsInLifeSkills` | `Curriculum.levels(in: .lifeSkills).count == 10` |
| `test_firstLevelIsM01` | `Curriculum.levels.first?.id == "M01"` |
| `test_levelsHaveUniqueIds` | All 50 ids are unique |
| `test_difficultyInRange` | Every `difficulty` is 1...5 |
| `test_vocabularyNonEmpty` | Every `vocabulary` is non-empty |
| `test_fallbackOnMissingJSON` | With `levels.json` removed, falls back to the single hardcoded level (does not crash) |
| `test_fallbackOnCorruptedJSON` | With `levels.json` containing malformed JSON, falls back to the hardcoded level |
| `test_fallbackLevelIsE05` | The fallback level's id is "E05" |

- [ ] All 11 tests pass in CI
- [ ] The fallback tests use a temporary file replacement strategy
  (copy the original JSON aside, write a broken one, reload, restore)

---

## Implementation Notes

`Curriculum` currently uses `Bundle.main.url(forResource: "levels", withExtension: "json")`.
The test bundle will not have this resource, so the fallback test naturally
triggers.

```swift
final class CurriculumTests: XCTestCase {
    func test_loadsAllFiftyLevels() {
        XCTAssertEqual(Curriculum.levels.count, 50)
    }

    func test_levelsInMath() {
        XCTAssertEqual(Curriculum.levels(in: .math).count, 25)
    }

    // ... remaining 9 tests
}
```

For the corruption test, write a temporary file to the test bundle's
resource path or use a custom `Bundle` subclass.

---

## Engine Risk

**Low** — pure data tests.

---

## Test Evidence Path

This file IS the test evidence. CI run logs show 11 tests passed.
