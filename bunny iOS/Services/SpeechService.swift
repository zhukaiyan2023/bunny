import AVFoundation
import CryptoKit

/// Text + delivery style is a stable key shared with tools/voiceover.py.
enum VoiceStyle: String { case normal, slow, encouraging }

struct OfflineVoiceCatalog {
    let files: [String: String]
    let directory: URL
    static func key(for text: String, style: VoiceStyle = .normal) -> String {
        let normalized = text.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        return SHA256.hash(data: Data((style.rawValue + "\n" + normalized).utf8))
            .map { String(format: "%02x", $0) }.joined()
    }
    init(directory: URL) {
        self.directory = directory
        files = (try? Data(contentsOf: directory.appendingPathComponent("catalog.json")))
            .flatMap { try? JSONDecoder().decode([String: String].self, from: $0) } ?? [:]
    }
    func url(for text: String, style: VoiceStyle) -> URL? {
        guard let name = files[Self.key(for: text, style: style)],
              name.range(of: "^[a-f0-9]{64}\\.(mp3|wav|m4a|aac)$", options: .regularExpression) != nil else { return nil }
        let url = directory.appendingPathComponent(name)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// Keep the recorded character voice when a pack only includes normal delivery.
    func playbackURLs(for text: String, style: VoiceStyle) -> [URL] {
        let styles: [VoiceStyle] = style == .normal ? [.normal] : [style, .normal]
        return styles.compactMap { url(for: text, style: $0) }.reduce(into: []) { urls, url in
            if !urls.contains(url) { urls.append(url) }
        }
    }
}

/// Singleton wrapper around AVSpeechSynthesizer + AVAudioEngine. Every scene
/// reads from this instance so the same line is never played twice in parallel.
@MainActor
final class SpeechService: NSObject {
    static let shared = SpeechService()

    nonisolated private let synthesizer = AVSpeechSynthesizer()
    nonisolated private let audioEngine = AVAudioEngine()
    nonisolated private let tonePlayer = AVAudioPlayerNode()
    nonisolated private let catalog: OfflineVoiceCatalog
    private var player: AVAudioPlayer?
    private var remainingRecordings: [URL] = []
    private var activeUtterance: ObjectIdentifier?
    private var completionHandler: (() -> Void)?
    private var pendingText = ""
    private var pendingStyle: VoiceStyle = .normal
    private(set) var isSpeaking = false
    private(set) var isPlayingRecordedVoice = false
    var bundledVoiceCount: Int { catalog.files.count }

    override convenience init() {
        self.init(voiceDirectory: Bundle.main.bundleURL.appendingPathComponent("VoiceAudio"))
    }

    init(voiceDirectory: URL) {
        catalog = OfflineVoiceCatalog(directory: voiceDirectory)
        super.init()
        synthesizer.delegate = self
        audioEngine.attach(tonePlayer)
        if let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1) {
            audioEngine.connect(tonePlayer, to: audioEngine.mainMixerNode, format: format)
        }
        try? audioEngine.start()
    }

    func warmUp() {
        // Pre-decode one short silence to keep the playback engine primed.
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("silence.wav")
        if !FileManager.default.fileExists(atPath: tmp.path) {
            let url = tmp
            let format = AVAudioFormat(standardFormatWithSampleRate: 22_050, channels: 1)
            if let format, let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 4_410) {
                buffer.frameLength = 4_410
                for i in 0..<4_410 { buffer.floatChannelData?[0][i] = 0 }
                if let audioFile = try? AVAudioFile(forWriting: url, settings: format.settings) {
                    try? audioFile.write(from: buffer)
                }
            }
        }
        if let recording = try? AVAudioPlayer(contentsOf: tmp) {
            recording.prepareToPlay()
            _ = recording
        }
    }

    func speak(_ text: String, style: VoiceStyle = .normal, completion: (() -> Void)? = nil) {
        stop()
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { completion?(); return }
        pendingText = text
        pendingStyle = style
        completionHandler = completion
        remainingRecordings = catalog.playbackURLs(for: text, style: style)
        playNextRecordingOrSystemVoice()
    }

    private func playNextRecordingOrSystemVoice() {
        while !remainingRecordings.isEmpty {
            let url = remainingRecordings.removeFirst()
            guard let recording = try? AVAudioPlayer(contentsOf: url) else { continue }
            player = recording
            recording.delegate = self
            recording.prepareToPlay()
            if recording.play() {
                isSpeaking = true
                isPlayingRecordedVoice = true
                return
            }
            player = nil
        }
        speakWithSystemVoice()
    }

    private func speakWithSystemVoice() {
        isPlayingRecordedVoice = false
        let utterance = AVSpeechUtterance(string: pendingText)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = pendingStyle == .slow ? 0.34 : 0.43
        utterance.pitchMultiplier = pendingStyle == .encouraging ? 1.12 : 1.08
        utterance.volume = 1
        activeUtterance = ObjectIdentifier(utterance)
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stop() {
        stopSpeech()
    }

    /// Synchronous, non-actor-isolated helper used by `deinit` and
    /// `UIApplication.willResignActiveNotification` cleanup. The underlying
    /// AVFoundation classes are thread-safe; we only mutate the public state
    /// via the main-actor `stop()` above.
    nonisolated func stopSpeech() {
        synthesizer.stopSpeaking(at: .immediate)
        tonePlayer.stop()
        // Pause the entire audio engine so any AVAudioPlayer sessions also
        // stop without needing to touch MainActor-isolated state.
        if audioEngine.isRunning { audioEngine.pause() }
    }

    private func finish() {
        activeUtterance = nil
        player = nil
        remainingRecordings.removeAll()
        isSpeaking = false
        isPlayingRecordedVoice = false
        let completion = completionHandler
        completionHandler = nil
        completion?()
    }

    func playSuccessTone() {
        playTone(frequencies: [523.25, 659.25, 783.99], noteDuration: 0.11, volume: 0.18)
    }

    func playTryAgainTone() {
        playTone(frequencies: [392.0, 329.63], noteDuration: 0.12, volume: 0.11)
    }

    private func playTone(frequencies: [Double], noteDuration: Double, volume: Float) {
        let sampleRate = 44_100.0
        let frameCount = AVAudioFrameCount(sampleRate * noteDuration * Double(frequencies.count))
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channel = buffer.floatChannelData?[0] else { return }
        buffer.frameLength = frameCount
        let framesPerNote = max(1, Int(sampleRate * noteDuration))
        for frame in 0..<Int(frameCount) {
            let noteIndex = min(frame / framesPerNote, frequencies.count - 1)
            let frameInNote = frame % framesPerNote
            let time = Double(frameInNote) / sampleRate
            let envelope = sin(Double.pi * Double(frameInNote) / Double(framesPerNote))
            channel[frame] = volume * Float(envelope * sin(2 * Double.pi * frequencies[noteIndex] * time))
        }
        if !audioEngine.isRunning { try? audioEngine.start() }
        tonePlayer.stop()
        tonePlayer.scheduleBuffer(buffer)
        tonePlayer.play()
    }
}

extension SpeechService: AVSpeechSynthesizerDelegate, AVAudioPlayerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor [weak self] in
            guard let self, self.activeUtterance == id else { return }
            self.finish()
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor [weak self] in
            guard let self, self.activeUtterance == id else { return }
            self.activeUtterance = nil
            self.completionHandler = nil
            self.isSpeaking = false
        }
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let id = ObjectIdentifier(player)
        Task { @MainActor [weak self] in
            guard let self, let current = self.player, ObjectIdentifier(current) == id else { return }
            if flag { self.finish() }
            else { self.player = nil; self.playNextRecordingOrSystemVoice() }
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        let id = ObjectIdentifier(player)
        Task { @MainActor [weak self] in
            guard let self, let current = self.player, ObjectIdentifier(current) == id else { return }
            self.player = nil
            self.playNextRecordingOrSystemVoice()
        }
    }
}