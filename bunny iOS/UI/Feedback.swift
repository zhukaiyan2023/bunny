import UIKit
import AudioToolbox

/// Tiny facade over UIImpactFeedbackGenerator + SystemSoundID for
/// consistent feel across the app. Pillar 1 (Calm): all feedback is
/// light or medium — never harsh. Pillar 4 (Privacy): no
/// third-party SDK.
///
/// Usage:
///     Feedback.shared.tap()
///     Feedback.shared.success()
///     Feedback.shared.tryAgain()
///     Feedback.shared.celebrate()
@MainActor
final class Feedback {
    static let shared = Feedback()

    private let lightImpact  = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let notification  = UINotificationFeedbackGenerator()

    // SystemSoundID values from <AudioToolbox/AudioServices.h>.
    // 1057 = Tink, 1103 = Tock, 1113 = TweetSent, 1114 = TweetFail,
    // 1322 = Anticipate, 1110 = BeginRecording, 1111 = EndRecording.
    private enum SoundID {
        static let tap:        UInt32 = 1103 // Tock
        static let success:    UInt32 = 1057 // Tink
        static let tryAgain:   UInt32 = 1073
        static let celebrate:  UInt32 = 1113 // TweetSent
    }

    private init() {
        // Warm up the generators to reduce first-tap latency.
        lightImpact.prepare()
        mediumImpact.prepare()
        rigidImpact.prepare()
        notification.prepare()
    }

    // MARK: - Haptics

    /// Soft tap. Used for any button press.
    func tap() {
        lightImpact.impactOccurred(intensity: 0.7)
        playSound(SoundID.tap)
    }

    /// Medium success. Used for correct answers / level completion.
    func success() {
        mediumImpact.impactOccurred(intensity: 0.85)
        playSound(SoundID.success)
    }

    /// Slightly stronger impact for wrong attempts, with a softer tone.
    func tryAgain() {
        rigidImpact.impactOccurred(intensity: 0.5)
        playSound(SoundID.tryAgain)
    }

    /// Celebration — long, multi-burst.
    func celebrate() {
        notification.notificationOccurred(.success)
        playSound(SoundID.celebrate)
        // Two follow-up taps for a "victory rhythm".
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.lightImpact.impactOccurred(intensity: 0.9)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) { [weak self] in
            self?.lightImpact.impactOccurred(intensity: 1.0)
        }
    }

    // MARK: - Audio

    private func playSound(_ id: UInt32) {
        AudioServicesPlaySystemSound(id)
    }
}
