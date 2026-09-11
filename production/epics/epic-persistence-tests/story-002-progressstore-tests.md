# Story S2-02 — ProgressStore Round-Trip Tests

**Epic**: EPIC-002 — Persistence Hardening + Unit Test Coverage
**Status**: Ready (depends on S2-01)
**GDD req**: TR-PERS-001..008
**ADR**: ADR-0003 (UserDefaults)
**Story type**: Test
**Acceptance test**: all tests pass in CI

---

## Context

`ProgressStore` is the single source of truth for all game state. A
bug here silently corrupts progress, stars, settings, or the onboarding
flag. We need exhaustive XCTest coverage that proves every key
round-trips correctly through `flush()` and reload.

---

## Acceptance Criteria

- [ ] `tests/unit/ProgressStoreTests.swift` exists in the `bunnyTests`
  target
- [ ] Each test uses a fresh `UserDefaults(suiteName:)` so tests are
  isolated and do not clobber the device state
- [ ] Test cases (one per key + boundary cases):

| Test | Description |
|---|---|
| `test_stars_defaultEmpty` | `stars(for:)` returns 0 for never-set level |
| `test_stars_roundTrip` | `setStars(3, for: "M01")` → reload → returns 3 |
| `test_stars_maxWins` | `setStars(1)` then `setStars(3)` → reload → returns 3 |
| `test_stars_downgradeDoesNothing` | `setStars(3)` then `setStars(1)` → returns 3 (max wins) |
| `test_unlockedLevel_defaultM01` | `unlockedLevel()` returns "M01" |
| `test_unlockNextLevel` | `unlockNextLevel(after: "M01")` → returns "M02" |
| `test_achievements_roundTrip` | `grantAchievement("ach.foo")` → reload → `hasAchievement` true |
| `test_sessionCount_increments` | First call returns 1; second call returns 2 |
| `test_lastPlayedDate_persists` | After `setLastPlayed(...)` → reload → same Date |
| `test_ttsRate_roundTrip` | `setTtsRate(0.5)` → reload → 0.5 |
| `test_dailySessionCapMinutes_roundTrip` | `setDailySessionCap(20)` → reload → 20 |
| `test_motionEnabled_roundTrip` | Persists true and false |
| `test_onboardingComplete_roundTrip` | `setOnboardingComplete(true)` → reload → true |
| `test_resetAllProgress_clearsAllKeys` | All keys return to defaults after `resetAllProgress()` |
| `test_corruptedStarsValue_defaultsEmpty` | Setting raw JSON to malformed bytes → `stars(for:)` returns 0, no crash |
| `test_flush_isIdempotent` | Calling `flush()` twice in a row is harmless |

- [ ] All 16 tests pass in CI
- [ ] No test ever calls `UserDefaults.standard` (uses `suiteName:` only)

---

## Implementation Notes

```swift
@MainActor
final class ProgressStoreTests: XCTestCase {
    var suiteName: String!
    var defaults: UserDefaults!
    var sut: ProgressStore!

    override func setUp() {
        super.setUp()
        suiteName = "bunny-tests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        sut = ProgressStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        sut = nil
        super.tearDown()
    }

    func test_stars_roundTrip() throws {
        sut.setStars(3, for: "M01")
        sut.flush()
        let reloaded = ProgressStore(defaults: defaults)
        XCTAssertEqual(reloaded.stars(for: "M01"), 3)
    }

    // ... remaining 15 tests
}
```

`ProgressStore` may need a small refactor to accept an injected
`UserDefaults` instance (currently it hardcodes `.standard`). The
refactor must not change the public API.

---

## Engine Risk

**Low** — requires minor refactor for DI; behavior must remain identical.

---

## Test Evidence Path

This file IS the test evidence. CI run logs show 16 tests passed.
