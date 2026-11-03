import SwiftUI

/// One haptic per player action, switchable in Settings (spec section 19, juice rules).
struct GameHaptics: ViewModifier {
    let enabled: Bool
    let correctCount: Int
    let petals: Int
    let won: Bool

    func body(content: Content) -> some View {
        if enabled {
            content
                .sensoryFeedback(.impact(weight: .light), trigger: correctCount)
                .sensoryFeedback(trigger: petals) { old, new in new < old ? .impact(flexibility: .soft, intensity: 0.7) : nil }   // never .error for kids
                .sensoryFeedback(.success, trigger: won) { _, new in new }
        } else {
            content
        }
    }
}
