# ADR-0003: UserDefaults Over Core Data for All Persistence

**Status**: Accepted
**Date**: 2026-01
**Deciders**: bunny team

---

## Context

bunny needs to persist:
- Stars per level (0–3 across 50 levels = `[String: Int]`)
- Unlocked level (single string)
- Achievements earned (set of strings, ≤ 16)
- Settings (TTS rate, motion, session cap, onboarding flag)
- Session counters and last-played date

All persisted data is **per-device, never synced** (Pillar 4: privacy).
Total storage footprint is small — under 10 KB.

---

## Decision

**Use `UserDefaults` exclusively**, wrapped in a single
`ProgressStore` singleton. No Core Data, no SQLite, no file-based JSON
in the app sandbox.

```swift
final class ProgressStore {
    static let shared = ProgressStore()
    private let defaults: UserDefaults

    func stars(for levelId: String) -> Int
    func setStars(_ stars: Int, for levelId: String)
    // ...
}
```

Detailed design: `design/gdd/persistence-system.md`.

---

## Alternatives Considered

### A. Core Data
- **Pros**: type-safe queries, schema migrations, mature.
- **Cons**: 50 KB minimum overhead, complex setup, way more than needed for 10 KB of data.
- **Why rejected**: massive overkill for our data volume.

### B. File-based JSON in app sandbox
- **Pros**: full control over schema, easy to inspect.
- **Cons**: manual file I/O, manual encoding, more failure modes, more code to test.
- **Why rejected**: `UserDefaults` already provides atomic writes, automatic plist encoding, and iOS-managed backup.

### C. SwiftData (iOS 17+)
- **Pros**: modern Apple-native persistence.
- **Cons**: deployment target is 26.5, so technically available; still overkill for 10 KB of data.
- **Why rejected**: same as Core Data — overkill.

### D. iCloud Key-Value Store
- **Pros**: cross-device sync for free.
- **Cons**: violates Pillar 4 (privacy — kid data should not leave the device).
- **Why rejected**: Pillar 4 explicitly forbids this.

---

## Consequences

### Positive
- Tiny binary footprint — `UserDefaults` is built-in
- Atomic writes handled by `UserDefaults`
- Type-safe via `ProgressStore` wrapper (no stringly-typed keys at call sites)
- Easy to mock in tests (`UserDefaults(suiteName:)`)
- Easy to wipe on "Reset Progress"

### Negative
- Migration requires manual schema versioning in `ProgressStore.bootstrap()`
- Reading/writing large dictionaries repeatedly can be slow (mitigated — we have < 10 KB)
- No query language — but we don't need one

### Neutral
- `ProgressStore` is a singleton (one of three allowed singletons)
- Keys are defined as static constants on `ProgressStore.Keys`; no
  string literals at call sites (enforced by code review and
  forbidden-patterns lint)

---

## Schema Migration Path

If the data shape changes:
1. Increment a `schemaVersion` constant
2. Add a migration block to `ProgressStore.bootstrap()` that detects the
   old shape and rewrites
3. Remove the migration block once the minimum app version is high
   enough that no old installs exist

---

## References

- `design/gdd/persistence-system.md`
- `bunny iOS/Services/ProgressStore.swift`

Last updated: 2026-01
