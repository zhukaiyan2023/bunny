# Audio System — GDD

**System slug**: SYS-EXP-004
**Status**: Approved (v1.0)
**Pillars served**: Pillar 1 (Calm), Pillar 5 (Adult-gated — speech rate adjustable)
**Last updated**: 2026-01

---

## Overview

The Audio System is the single source of all sound in bunny: text-to-speech
narration, ambient scene sounds, and feedback chimes. It is implemented as
`SpeechService` (currently TTS-only; ambient SFX deferred to v2).

---

## Requirements

| ID | Requirement |
|---|---|
| **TR-AUD-001** | The system MUST provide a `speak(_ text: String, rate: Double?)` method that narrates text via `AVSpeechSynthesizer`. |
| **TR-AUD-002** | The system MUST default to `AVSpeechSynthesisVoice(language: "en-US")`. |
| **TR-AUD-003** | The system MUST read the rate from `ProgressStore.shared.ttsRate` if no rate is provided. |
| **TR-AUD-004** | The system MUST gracefully degrade (no-op) if TTS is unavailable (e.g., voice not installed). |
| **TR-AUD-005** | The system MUST NOT play any sound at app launch without explicit user action. |
| **TR-AUD-006** | The system MUST respect the iOS silent switch (`AVAudioSession` category `.ambient`). |
| **TR-AUD-007** | The system MUST allow current speech to be interrupted by a new `speak(...)` call. |
| **TR-AUD-008** | v2 ambient SFX (when added) MUST be loaded via `SKAudioNode` from bundle resources. |

---

## API

```swift
final class SpeechService {
    static let shared = SpeechService()
    private let synth = AVSpeechSynthesizer()

    func speak(_ text: String, rate: Double? = nil)
    func speak(_ words: [String], rate: Double? = nil)  // speaks in order, pauses between
    func stop()                                          // interrupt current speech
    var isSpeaking: Bool { get }
}
```

---

## Voice Configuration

| Property | Value |
|---|---|
| Language | `en-US` |
| Voice | `AVSpeechSynthesisVoice(language: "en-US")` (system default — usually Samantha) |
| Default rate | 0.45 (range 0.30–0.70) |
| Pitch | 1.0 (no modification) |
| Volume | 0.9 |

---

## Audio Session

```swift
try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .spokenAudio)
try AVAudioSession.sharedInstance().setActive(true, options: [])
```

- `.ambient`: respects silent switch; mixes with other apps
- `.spokenAudio`: optimized for voice — ducking, EQ
- Set once at app launch in `BunnyAppDelegate`

---

## Source

- `bunny iOS/Services/SpeechService.swift`

---

## Future Work (v2)

- Pre-recorded child-friendly voice clips for common words
- Ambient scene audio (bakery oven, bathroom water, etc.) via `SKAudioNode`
- Feedback chime library (completion, retry, encouragement)

---

## Acceptance Criteria

- [ ] Every spoken prompt in every scene is delivered via `SpeechService`
- [ ] TTS respects the `ttsRate` setting
- [ ] No scene crashes if TTS is unavailable
- [ ] Calling `speak` while speaking interrupts the previous speech
- [ ] Silent switch on iPhone silences all bunny audio
- [ ] Tapping the speaker icon in the HUD re-speaks the prompt within 200 ms

---

## Open Questions

- Should we ship with a pre-recorded kid voice for the v2 release?
  (Tracked.)

Last updated: 2026-01
