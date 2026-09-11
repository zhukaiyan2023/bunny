# ADR-0005: Curriculum as JSON Data, Not Swift Literals

**Status**: Accepted
**Date**: 2026-01
**Deciders**: bunny team

---

## Context

bunny ships 50 levels across 3 learning areas (Math, English, Life
Skills). Each level has:

- A unique id (`M01`–`M25`, `E01`–`E15`, `L01`–`L10`)
- An area
- A title and instruction (child-facing copy)
- A `SceneKind` reference
- A vocabulary list (3–10 words)
- A difficulty (1–5)

Adding a new level is a designer-driven activity. We need a workflow
that lets designers iterate without programmer involvement.

---

## Decision

**Store the curriculum as JSON in `bunny iOS/Resources/levels.json`**,
decoded at runtime into a typed `[LevelDefinition]`. The `Curriculum`
singleton owns the loading + fallback logic.

```swift
struct LevelDefinition: Identifiable, Codable, Equatable {
    let id: String
    let area: LearningArea
    let title: String
    let scene: SceneKind
    let instruction: String
    let vocabulary: [String]
    let difficulty: Int
}

enum Curriculum {
    static let levels: [LevelDefinition] = /* load levels.json */
    static func levels(in area: LearningArea) -> [LevelDefinition]
}
```

Detailed design: `design/gdd/curriculum-system.md`.

---

## Alternatives Considered

### A. Swift literals in `Curriculum.swift`
- **Pros**: type-safe at compile time, easy to navigate in Xcode.
- **Cons**: every new level is a code change + PR + merge; designers blocked on programmers; diff noise.
- **Why rejected**: scales poorly past 10–15 levels.

### B. Plist instead of JSON
- **Pros**: Apple-native, Xcode-editable as a table.
- **Cons**: array-of-dicts is awkward in plist; JSON is more familiar to non-Apple tooling; plist doesn't round-trip cleanly with Swift Codable.
- **Why rejected**: JSON + Swift Codable is the modern choice.

### C. SQLite / Core Data content table
- **Pros**: queryable, sortable, indexable.
- **Cons**: massive overkill for 50 rows; pulls in a persistence layer for read-only data.
- **Why rejected**: violates YAGNI.

### D. Per-level Swift files (Level01.swift, Level02.swift, …)
- **Pros**: maximum flexibility per level.
- **Cons**: 50 files, none of them self-describing, impossible to navigate.
- **Why rejected**: doesn't scale.

---

## Consequences

### Positive
- Designers can add/edit levels via JSON edit alone
- 50 levels fit in 54 lines (current `levels.json` size)
- Schema is enforced by the `LevelDefinition` struct's `Codable`
- A failed decode gracefully falls back to a single hardcoded level
- v2 localization can swap `levels.json` for `levels.<locale>.json`

### Negative
- Scene-specific fields (e.g., "which objects are in this scene") live
  inside scene code, not in JSON — designers must coordinate with
  programmers for visual changes
- Adding a new `SceneKind` enum value is still a Swift edit (mitigated —
  existing kinds cover all 50 levels; new kinds are rare)

### Neutral
- The `Curriculum` singleton loads on first access; the JSON file is
  bundled in the app, so no file I/O failure mode
- A schema validator (XCTest) verifies the JSON shape at every CI build

---

## Workflow

### Designer adds a new level
1. Open `bunny iOS/Resources/levels.json`
2. Append an entry matching the schema
3. (Optional) Add new background image to `.xcassets/<SceneName>.imageset/`
4. Build and run — the level appears in `AreaScene` automatically

### Programmer adds a new `SceneKind`
1. Add a new case to `SceneKind` enum in `Curriculum.swift`
2. Add the new case to `GameSceneFactory.makeScene(size:level:)` switch
3. Update the schema validator test
4. Commit

---

## References

- `design/gdd/curriculum-system.md`
- `bunny iOS/Models/Curriculum.swift`
- `bunny iOS/Resources/levels.json`

Last updated: 2026-01
