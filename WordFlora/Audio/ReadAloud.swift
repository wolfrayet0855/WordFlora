import AVFoundation
import UIKit

/// Reads the clue out loud with the system voice (works offline, no permissions, nothing recorded).
/// Hidden while VoiceOver runs so the clue is never spoken twice.
@MainActor
final class ReadAloud {
    static let shared = ReadAloud()
    private let synth = AVSpeechSynthesizer()

    nonisolated static func script(hint: String, extra: String?, simpler: String?) -> String {
        ([hint, extra, simpler].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }).filter { !$0.isEmpty }.joined(separator: " ")
    }
    nonisolated static func shouldOffer(voiceOverRunning: Bool) -> Bool { !voiceOverRunning }

    func speak(_ text: String) {
        stop()
        guard !text.isEmpty else { return }
        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
        u.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        synth.speak(u)
    }
    func stop() { if synth.isSpeaking { synth.stopSpeaking(at: .immediate) } }
}
