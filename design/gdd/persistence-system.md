# Persistence System — GDD

**System slug**: SYS-FOUND-002
**Status**: Approved (v1.0)
**Pillars served**: Pillar 3 (Persistence — never lose progress), Pillar 4 (Privacy — local only)
**Last updated**: 2026-01

---

## Overview

The Persistence System owns all read/write of game state. It is the **only
module that touches `UserDefaults`**. Every other system asks
`ProgressStore.shared` for the data it needs.

Why a wrapper?
- Single point to add schema migration later
- Single point to flush before scene teardown
- Single point to enforce typed keys (no stringly-typed `defaults.string(forKey:)`)
- Single point to mock in tests

---

## Requirements

| ID | Requirement |
|---|---|
| **TR-PERS-001** | The system MUST be a single shared instance (`ProgressStore.shared`). |
| **TR-PERS-002** | All keys MUST be defined as static `String` constants on `ProgressStore.Keys`. No string literals at call sites. |
| **TR-PERS-003** | The system MUST persist, at minimum: stars per level, unlocked levels, achievements earned, session-count, last-played-date, settings (TTS rate, motion, session cap). |
| **TR-PERS-004** | The system MUST call `UserDefaults.synchronize()` (or equivalent flush) at every scene teardown. |
| **TR-PERS-005** | The system MUST be safe to call from any thread; writes serialize internally. |
| **TR-PERS-006** | The system MUST gracefully handle corrupted values (return defaults, do not crash). |
| **TR-PERS-007** | The system MUST never write to iCloud, Keychain (except for parent gate token if added later), network, or any external location. |
| **TR-PERS-008** | Resetting progress MUST require double-parent-gate confirmation. |

---

## Stored Data

| Key | Type | Default | Purpose |
|---|---|---|---|
| `keys.starsPerLevel` | `[String: Int]` (level id → 0..3) | `{}` | Highest stars ever earned |
| `keys.unlockedLevel` | `String` (level id) | `"M01"` | Furthest unlocked level |
| `keys.achievements` | `Set<String>` (achievement ids) | `[]` | Earned achievements |
| `keys.sessionCount` | `Int` | `0` | Total sessions launched |
| `keys.lastPlayedDate` | `Date` | `nil` | For "X days since first play" achievements |
| `keys.ttsRate` | `Double` (0.3...0.7) | `0.45` | Speech rate |
| `keys.motionEnabled` | `Bool` | `true` | Disable to honor Reduce Motion |
| `keys.dailySessionCapMinutes` | `Int` | `15` | Parent-set cap |
| `keys.parentGateFailCount` | `Int` | `0` | Rate-limit parent gate attempts |
| `keys.onboardingComplete` | `Bool` | `false` | First-run flag |

---

## API

```swift
final class ProgressStore {
    static let shared = ProgressStore()
    private let defaults: UserDefaults

    enum Keys {
        static let starsPerLevel = "bunny.starsPerLevel"
        static let unlockedLevel = "bunny.unlockedLevel"
        // ...
    }

    func bootstrap()
    func stars(for levelId: String) -> Int
    func setStars(_ stars: Int, for levelId: String)
    func unlockedLevel() -> String
    func unlockNextLevel(after levelId: String)
    func hasAchievement(_ id: String) -> Bool
    func grantAchievement(_ id: String)
    func resetAllProgress()  // requires double parent gate
    func flush()
}
```

---

## Thread Safety

All writes go through a private serial `DispatchQueue`. Reads are synchronous
on the calling thread but lock-free (the underlying `UserDefaults` is
thread-safe for reads; writes queue internally).

---

## Migration Strategy

If the data shape changes (e.g., adding a new field), increment a schema
version constant and run a migration block in `bootstrap()`. The migration
block is the ONLY place that reads and rewrites existing data.

---

## Source

- `bunny iOS/Services/ProgressStore.swift`

---

## Acceptance Criteria

- [ ] All stored data survives app kill/restart
- [ ] Resetting progress wipes all 10 keys to defaults (verified by XCTest)
- [ ] Corrupted `starsPerLevel` value (e.g., wrong JSON) returns empty map, does not crash
- [ ] No other file in the codebase calls `UserDefaults.standard.set(...)`
  directly (enforced by code review + a forbidden-patterns lint)
- [ ] `flush()` is called in every scene's `willMove(from:)`

---

## Open Questions

- Should we use a custom Codable container for the stars-per-level dict?
  Currently `JSONEncoder/JSONDecoder` for `[String: Int]`. (Tracked as
  optimization, not blocking.)

Last updated: 2026-01
