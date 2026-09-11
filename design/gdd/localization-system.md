# Localization System — GDD

**System slug**: SYS-FOUND-003
**Status**: Deferred (v1 stub)
**Pillars served**: Pillar 4 (Privacy — no localization data leaves device)
**Last updated**: 2026-01

---

## Overview

v1 of bunny is **English-only**. All copy is hardcoded in the Swift
sources and `levels.json`. This stub GDD documents the v2 migration plan
for adding localization.

---

## v1 Stub Behavior

- All UI strings are inline `String` literals in scene / UI files
- `levels.json` instructions and vocabulary are English
- The `SpeechService` is hardcoded to `en-US`
- No `.strings` files, no `.lproj` folders

---

## v2 Migration Plan

When localization is requested (likely Spanish, French, Mandarin first):

1. **Extract all strings** into a `Localizable.strings` file per locale
2. **Replace inline literals** with `NSLocalizedString(...)` or
   `String(localized: ...)`
3. **Translate `levels.json`** into per-locale `levels.<locale>.json` files
4. **Add a `locale` enum** to `SpeechService` mapping locale → voice
5. **Add a locale picker** to the parent area settings
6. **Ship `.lproj` folders** for each supported language

---

## v2 Requirements (draft)

| ID | Requirement (draft) |
|---|---|
| **TR-LOC-001** | All user-facing strings MUST be extracted into `Localizable.strings`. |
| **TR-LOC-002** | The system MUST support `en`, `es`, `fr`, `zh-Hans` at v2 launch. |
| **TR-LOC-003** | The TTS voice MUST match the current locale. |
| **TR-LOC-004** | The locale picker MUST be in the parent area only (children don't change locale). |
| **TR-LOC-005** | The system MUST gracefully fall back to `en` if a locale string is missing. |

---

## Source

- v1: hardcoded strings in `bunny iOS/**/*.swift` and `bunny iOS/Resources/levels.json`
- v2: `bunny iOS/Resources/<locale>.lproj/Localizable.strings`,
  `bunny iOS/Resources/<locale>/levels.json`

---

## Acceptance Criteria (v2)

- [ ] No hardcoded English string in any scene (verified by string-extraction lint)
- [ ] Switching locale updates all UI strings within 200 ms
- [ ] TTS voice changes to match the locale
- [ ] Missing translations fall back to English without crash

---

## Open Questions

- Which locale first? Spanish is the obvious choice for a US app.
- Should the v2 translation effort use a professional translation service
  or community translation? (Pillar 4 may favor professional + paid.)

Last updated: 2026-01
