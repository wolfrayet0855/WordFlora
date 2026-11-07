import AVFoundation
import UIKit

/// Reads the clue out loud with the best installed system voice (offline, no permissions, nothing recorded).
/// One utterance per sentence with short pauses; the garden bed is ducked while speaking. Hidden under VoiceOver.
@MainActor
final class ReadAloud: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = ReadAloud()
    private let synth = AVSpeechSynthesizer()
    private var pending = 0
    /// The utterances of the current `speak`, so a cancelled or older one never counts as the end of this one.
    private var live = Set<ObjectIdentifier>()
    /// Called once when every sentence of the current `speak` was spoken to the end (not on a stop or a cancel).
    private var onFinish: (() -> Void)?
    private var cachedVoice: AVSpeechSynthesisVoice?

    override init() {
        super.init()
        synth.delegate = self
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] n in
            if (n.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt) == AVAudioSession.InterruptionType.began.rawValue { Task { @MainActor in self?.stop() } }
        }
        NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] n in
            if (n.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt) == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue { Task { @MainActor in self?.stop() } }
        }
    }

    nonisolated static func script(hint: String, extra: String?, simpler: String?) -> String {
        ([hint, extra, simpler].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }).filter { !$0.isEmpty }.joined(separator: " ")
    }
    /// Each piece becomes sentences that end with punctuation, so the voice phrases them with natural falls.
    nonisolated static func sentences(hint: String, extra: String?, simpler: String?) -> [String] {
        var out = [String]()
        for piece in [hint, extra, simpler].compactMap({ $0?.trimmingCharacters(in: .whitespacesAndNewlines) }) where !piece.isEmpty {
            var current = ""
            for ch in piece {
                current.append(ch)
                if ".!?".contains(ch) { out.append(current.trimmingCharacters(in: .whitespaces)); current = "" }
            }
            let rest = current.trimmingCharacters(in: .whitespaces)
            if !rest.isEmpty { out.append(rest + ".") }
        }
        return out
    }
    nonisolated static func shouldOffer(voiceOverRunning: Bool) -> Bool { !voiceOverRunning }

    private func voice() -> AVSpeechSynthesisVoice? {
        if let v = cachedVoice { return v }
        let lang = AVSpeechSynthesisVoice.currentLanguageCode()
        let all = AVSpeechSynthesisVoice.speechVoices()
        let candidates = all.map { v in
            VoicePicker.Candidate(id: v.identifier, name: v.name, language: v.language,
                                  quality: v.quality == .premium ? .premium : (v.quality == .enhanced ? .enhanced : .standard),
                                  isNovelty: v.voiceTraits.contains(.isNoveltyVoice), isPersonal: v.voiceTraits.contains(.isPersonalVoice))
        }
        let chosen = VoicePicker.best(from: candidates, language: lang).flatMap { pick in all.first { $0.identifier == pick.id } }
            ?? AVSpeechSynthesisVoice(language: lang)
        cachedVoice = chosen
        return chosen
    }

    func speak(hint: String, extra: String?, simpler: String?, onFinish: (() -> Void)? = nil) {
        stop()
        let lines = Self.sentences(hint: hint, extra: extra, simpler: simpler)
        guard !lines.isEmpty else { return }
        // Speech plays even on silent because the player asked for it; the garden bed ducks underneath.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        SoundPlayer.shared.duckAmbient(true)
        let v = voice()
        pending = lines.count
        self.onFinish = onFinish
        for (i, line) in lines.enumerated() {
            let u = AVSpeechUtterance(string: line)
            u.voice = v
            u.rate = 0.42
            u.pitchMultiplier = 1.05
            u.volume = 1.0
            u.preUtteranceDelay = i == 0 ? 0.2 : 0
            u.postUtteranceDelay = 0.4
            u.prefersAssistiveTechnologySettings = false
            live.insert(ObjectIdentifier(u))
            synth.speak(u)
        }
    }

    func stop() {
        onFinish = nil
        live.removeAll()
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
        finish()
    }

    private func finish() {
        pending = 0
        SoundPlayer.shared.duckAmbient(false)
        SoundPlayer.configureSession()
    }

    nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in
            guard live.remove(id) != nil else { return }         // from an earlier, stopped speak
            pending -= 1
            if live.isEmpty {
                let done = onFinish
                onFinish = nil
                finish()
                done?()
            }
        }
    }
    nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor in
            guard live.remove(id) != nil else { return }
            onFinish = nil                                          // cut short: not read to the end
            pending = max(0, pending - 1); if pending == 0 { finish() }
        }
    }
}
