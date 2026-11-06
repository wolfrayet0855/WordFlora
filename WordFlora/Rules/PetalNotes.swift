import Foundation
import CoreGraphics

/// The petal sound toy on the plant page (owner approved for this release). Tapping a love petal under the plant
/// plays its note; tapping the little love flower at the row's start plays all five. Tapping the plant itself still
/// says hello. Notes are the C major pentatonic (no fourth, no seventh), so any order of taps sounds kind.
/// Sound off: silent. Calm: softer. Reduce Motion: no bounce, the notes still play. Quiet Garden: allowed, and
/// nothing is counted (the toy is not a hello and moves no quest).
enum PetalNotes {
    /// C5 D5 E5 G5 A5.
    static let frequencies: [Double] = [523.25, 587.33, 659.25, 783.99, 880.00]
    static let duration: Double = 0.9
    /// Seconds between notes when the whole row plays.
    static let runGap: Double = 0.16

    static func frequency(petal i: Int) -> Double { frequencies[min(max(i, 0), frequencies.count - 1)] }

    /// A petal plays its own note; the love flower (nil) plays the row from left to right.
    static func notes(forTap petal: Int?) -> [Int] { petal.map { [$0] } ?? Array(frequencies.indices) }

    /// 0 with Sound off; Calm plays at about half.
    static func volume(soundOn: Bool, calm: Bool) -> Float {
        guard soundOn else { return 0 }
        return calm ? 0.22 : 0.45
    }

    static func haptic(hapticsOn: Bool) -> Bool { hapticsOn }

    /// Which petal a tap at `x` (in the pill's own space) lands on: nil for the love flower, else 0...4.
    /// Mirrors PetalPips' layout: flower 1.4w plus 0.2w, then pips of width w spaced 0.3w.
    static func petalIndex(x: CGFloat, pipWidth w: CGFloat, leading: CGFloat) -> Int? {
        let firstPip = leading + 1.6 * w + 0.3 * w
        guard x >= firstPip - 0.15 * w else { return nil }
        let i = Int(((x - (firstPip - 0.15 * w)) / (1.3 * w)).rounded(.down))
        return min(max(i, 0), frequencies.count - 1)
    }

    /// One soft pluck: a sine with a little octave, a 10 ms rise and a smooth fall to silence.
    static func samples(frequency: Double, sampleRate: Double, volume: Float) -> [Float] {
        let n = Int(sampleRate * duration)
        guard n > 0, volume > 0 else { return Array(repeating: 0, count: max(0, n)) }
        let attack = 0.01 * sampleRate
        return (0..<n).map { i in
            let t = Double(i) / sampleRate
            let rise = min(1, Double(i) / attack)
            let fall = exp(-4.5 * t) * (1 - Double(i) / Double(n))     // reaches exactly 0 at the end
            let wave = (sin(2 * .pi * frequency * t) + 0.25 * sin(4 * .pi * frequency * t)) / 1.25
            return Float(wave * rise * fall) * volume
        }
    }
}

enum PetalNotesCopy {
    /// The VoiceOver name of the petal row on the plant page.
    static let button = "Play petal notes"
}
