# Performance Budgets — bunny

Last verified: 2026-01

SpriteKit is highly optimized for 2D, but children's devices vary widely (iPhone
SE through iPad Pro, Apple TV HD through Apple TV 4K). These budgets keep the
experience smooth across the entire target matrix.

## Frame Budget

| Metric | Target | Hard Cap |
|---|---|---|
| **Frame time** | ≤ 10 ms (target 6 ms) | 16.6 ms (60 fps) |
| **`update(_:)` cost** | < 1 ms | < 3 ms |
| **Physics step** | < 2 ms | < 4 ms |
| **Draw calls per frame** | < 80 | < 150 |
| **Sprite count per scene** | < 40 | < 80 |
| **Texture atlas count** | 1 per scene | 3 per scene |
| **Particles on-screen** | < 100 | < 250 |
| **Audio voices** | < 6 | < 12 |

## Memory

| Metric | Target | Hard Cap |
|---|---|---|
| **Steady-state RAM** | < 150 MB | < 250 MB |
| **Per-scene texture RAM** | < 30 MB | < 60 MB |
| **Audio buffers cached** | < 8 MB | < 16 MB |

## Device Tiers

| Tier | Devices | Adaptation |
|---|---|---|
| **High** | iPhone 13+, iPad (6th gen)+, Apple TV 4K | Full particle / lighting / shadows |
| **Medium** | iPhone 11 / SE 2, iPad (5th gen), Apple TV HD | Reduce particle count by 50%, disable shadows |
| **Low** | (none targeted) | N/A — minimum spec is iPhone SE 2 / iPad 5 / Apple TV HD |

## Profiling Tooling

- **Instruments → Time Profiler**: per-scene `update` cost
- **Instruments → Allocations**: texture cache behavior, retain cycles
- **Instruments → Core Animation**: frame hitches
- **`SKView.showsFPS = true`** in DEBUG builds only; logged once on `viewDidAppear`

## Anti-Patterns

| Pattern | Why it's wrong |
|---|---|
| Allocating arrays in `update(_:)` | GC pressure, frame hitches |
| Reading from `UserDefaults` in `update` | Disk I/O on the render thread |
| Using `SKFieldNode` for ambient effects | Costly; prefer particle emitters |
| Texture atlas spanning > 2048×2048 | Page-out risk on iPhone SE 2 |
| Heavy work inside `didEvaluateActions` | Runs every frame; move to async |
| Synchronous network calls in scene init | Will hang first frame |

Last verified: 2026-01
