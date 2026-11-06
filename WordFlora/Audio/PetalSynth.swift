import AVFoundation

/// Plays PetalNotes' plucks, made in memory (no sound files). Uses the app's ambient session, so the silent switch
/// mutes it and the player's own music keeps playing. A few player nodes take turns so quick taps can ring together.
@MainActor
final class PetalSynth {
    static let shared = PetalSynth()

    private let engine = AVAudioEngine()
    private var nodes: [AVAudioPlayerNode] = []
    private var next = 0
    private var buffers: [String: AVAudioPCMBuffer] = [:]
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)
    private var pending: [DispatchWorkItem] = []

    private init() {}

    /// Plays the notes for one tap (`PetalNotes.notes(forTap:)`), quietly at `volume`. Nothing happens at volume 0.
    func play(tap petal: Int?, volume: Float) {
        guard volume > 0 else { return }
        pending.forEach { $0.cancel() }; pending.removeAll()
        for (k, note) in PetalNotes.notes(forTap: petal).enumerated() {
            if k == 0 { pluck(note, volume: volume); continue }
            let item = DispatchWorkItem { [weak self] in self?.pluck(note, volume: volume) }
            pending.append(item)
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(k) * PetalNotes.runGap, execute: item)
        }
    }

    func stop() {
        pending.forEach { $0.cancel() }; pending.removeAll()
        nodes.forEach { $0.stop() }
    }

    private func pluck(_ note: Int, volume: Float) {
        guard let format, startIfNeeded(format), let buffer = buffer(note, volume: volume, format: format) else { return }
        let node = nodes[next]
        next = (next + 1) % nodes.count
        node.stop()
        node.scheduleBuffer(buffer, at: nil, options: [])
        node.play()
    }

    private func startIfNeeded(_ format: AVAudioFormat) -> Bool {
        if nodes.isEmpty {
            for _ in 0..<PetalNotes.frequencies.count {
                let n = AVAudioPlayerNode()
                engine.attach(n)
                engine.connect(n, to: engine.mainMixerNode, format: format)
                nodes.append(n)
            }
        }
        if engine.isRunning { return true }
        engine.prepare()
        return (try? engine.start()) != nil
    }

    private func buffer(_ note: Int, volume: Float, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let key = "\(note)-\(volume)"
        if let b = buffers[key] { return b }
        let samples = PetalNotes.samples(frequency: PetalNotes.frequency(petal: note), sampleRate: format.sampleRate, volume: volume)
        guard let b = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)),
              let channel = b.floatChannelData?[0] else { return nil }
        b.frameLength = AVAudioFrameCount(samples.count)
        samples.withUnsafeBufferPointer { channel.update(from: $0.baseAddress!, count: samples.count) }
        buffers[key] = b
        return b
    }
}
