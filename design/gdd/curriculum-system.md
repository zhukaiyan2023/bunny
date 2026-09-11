# Curriculum System — GDD

**System slug**: SYS-CONT-001
**Status**: Approved (v1.0)
**Pillars served**: Pillar 2 (Tasks), Pillar 3 (Persistence)
**Last updated**: 2026-01

---

## Overview

The Curriculum System is the **authoritative source of content** for bunny.
It owns the 50 levels defined in `bunny iOS/Resources/levels.json` and
provides typed access to them at runtime.

This system is **data-first**: designers edit JSON, not code. Adding a new
level is a JSON edit + asset drop; it should never require a programmer.

---

## Requirements (TR IDs)

| ID | Requirement |
|---|---|
| **TR-CURR-001** | The system MUST load all 50 levels from `levels.json` at app launch. |
| **TR-CURR-002** | The system MUST gracefully fall back to a single hardcoded level if the JSON cannot be decoded. |
| **TR-CURR-003** | The system MUST expose a typed query for `levels(in: LearningArea)` returning levels filtered by area. |
| **TR-CURR-004** | Every `LevelDefinition` MUST validate: non-empty `id`, valid `area`, `difficulty ∈ [1, 5]`, non-empty `vocabulary`. |
| **TR-CURR-005** | Level IDs MUST follow the pattern `[MEL]<NN>` where M=Math, E=English, L=Life. |
| **TR-CURR-006** | Adding a new level MUST require only a JSON edit + (optionally) a new asset. No Swift code change. |
| **TR-CURR-007** | The system MUST be the only place that knows the on-disk JSON shape. All other systems consume `LevelDefinition` values. |

---

## Data Model

```swift
enum LearningArea: String, Codable, CaseIterable, Identifiable {
    case math = "Math"
    case english = "English"
    case lifeSkills = "Life Skills"
}

enum SceneKind: String, Codable {
    // 50 values across 3 areas (see enum in Curriculum.swift)
    case bakery, trainBuilder, bridge, rocket, garden,
         farm, balanceBridge, riverJumps, picnic, mountain,
         campfire, delivery, robotRepair, tower, cave,
         lilyPond, festival, castle, mirrorLake, spaceStation,
         measureGarden, clockTrain, toyShop, fairPicnic, market,
         wakeUp, bathroomMorning, brushTeeth, getDressed, breakfast,
         setTable, cooking, dinner, dishes, laundry,
         cleanBedroom, findTeddy, bathTime, bedtime, dayAtHome,
         rainbowRoom, cafe, bathroomRoutine, weatherWardrobe, homeSafety,
         street, morningCards, adventureBag, playground, helperFestival
}

struct LevelDefinition: Identifiable, Codable, Equatable {
    let id: String           // "M01", "E05", "L10"
    let area: LearningArea
    let title: String        // "Bakery Box Rescue"
    let scene: SceneKind     // .bakery
    let instruction: String  // "Pour the milk into the cup."
    let vocabulary: [String] // ["milk", "cup", "bowl", "spoon"]
    let difficulty: Int      // 1...5
}
```

### JSON shape (`levels.json`)

```json
[
  {
    "id": "M01",
    "area": "Math",
    "title": "Bakery Box Rescue",
    "scene": "bakery",
    "instruction": "Help Pip pack three croissants into the box.",
    "vocabulary": ["croissant", "box", "counter", "tray"],
    "difficulty": 2
  },
  ...
]
```

---

## Source

- `bunny iOS/Models/Curriculum.swift` — enum + struct + loader
- `bunny iOS/Resources/levels.json` — 50 entries

---

## Consumer Systems

| Consumer | How it uses the data |
|---|---|
| `Routing System` | Reads `LevelDefinition` to populate `SceneRouter.Route` |
| `Math / English / Life Skills` systems | Reads `scene`, `instruction`, `vocabulary` to instantiate the right scene |
| `UI / HUD` | Reads `title` and `instruction` to render prompts |
| `Audio System` | Reads `instruction` and `vocabulary[]` for TTS narration |
| `Progression System` | Reads `id` to mark completion and unlock next level |

---

## Adding a New Level (designer workflow)

1. Open `bunny iOS/Resources/levels.json`
2. Append a new entry matching the schema above
3. (Optional) Add a new background image to `bunny iOS/Assets.xcassets/<SceneName>.imageset/`
4. (Optional) Add a new `SceneKind` case to the `SceneKind` enum in `Curriculum.swift`
5. Run the build; the level appears in `AreaScene` automatically

> **Guardrail**: The `SceneKind` enum is closed (Codable). Adding a new scene
> type requires a Swift edit. If the scene is functionally identical to an
> existing kind (same mechanic, different art), reuse the existing kind.

---

## Validation

A `levels-validator` XCTest target verifies:

- Exactly 50 entries
- IDs are unique and follow `[MEL]<NN>` pattern
- Every `difficulty ∈ [1, 5]`
- Every `area` is a valid `LearningArea`
- Every `scene` is a valid `SceneKind`
- No empty `vocabulary` arrays

Runs at every CI build. A failure blocks the merge.

---

## Acceptance Criteria

- [ ] Loading `levels.json` returns 50 levels in the documented order
- [ ] Removing the JSON file falls back to the hardcoded `fallback` level (E05)
- [ ] Malformed JSON falls back to the hardcoded level (does not crash)
- [ ] `Curriculum.levels(in: .math)` returns exactly 25 levels
- [ ] `Curriculum.levels(in: .english)` returns exactly 15 levels
- [ ] `Curriculum.levels(in: .lifeSkills)` returns exactly 10 levels
- [ ] JSON schema validator test passes

---

## Open Questions

None.

Last updated: 2026-01
