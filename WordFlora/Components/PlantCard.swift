import SwiftUI

struct PlantCard: View {
    let plant: PlantCollectible
    var compact = false
    /// In a garden row: stretch to the row's height so both cards in the row line up.
    var fillsHeight = false
    /// Pruning Pro: a faded bloom shows on this plant today (the only cue on the card: no badge, dot or number).
    var fadedBloom = false

    private var earned: Bool { plant.earnedCount > 0 }

    var body: some View {
        VStack(spacing: compact ? 4 : 8) {
            ZStack(alignment: .topTrailing) {
                Image(plant.imageName)
                    .resizable().scaledToFit()
                    .frame(height: compact ? 64 : 92)
                    .saturation(earned ? 1 : 0)
                    .brightness(earned ? 0 : -0.55)
                    .opacity(earned ? 1 : 0.55)
                    .overlay(alignment: .top) {
                        if fadedBloom { FadedBloomView().frame(width: compact ? 22 : 30, height: compact ? 22 : 30).offset(x: 8, y: 4) }
                    }
                    .accessibilityHidden(true)
                if !earned {
                    // A soft "on its way" sparkle, never a lock (no lock icons anywhere in the app).
                    Image(systemName: "sparkles").font(.caption2).foregroundStyle(Color.appPrimaryText.opacity(0.5)).padding(4)
                }
            }
            Text(earned ? plant.name : "Not found yet")
                .font(Theme.font(compact ? .footnote : .subheadline, weight: .bold))
                .foregroundStyle(Color.appPrimaryText)
                .lineLimit(3).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            if earned && !compact {
                Text(plant.botanicalName).font(Theme.font(.caption)).italic()
                    .foregroundStyle(Color.secondaryText).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            }
            if plant.earnedCount > 1 {
                Label("×\(plant.earnedCount)", systemImage: "leaf.fill").font(Theme.font(.caption, weight: .bold)).foregroundStyle(Color.successText)
            }
        }
        .padding(compact ? Space.s : Space.m)
        .frame(maxWidth: .infinity, maxHeight: fillsHeight ? .infinity : nil, alignment: .top)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(earned ? Color.appAccent.opacity(0.45) : Color.appPrimaryText.opacity(0.08)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(fadedBloom ? PruningProCopy.plantLabel(Self.label(name: plant.name, botanicalName: plant.botanicalName, level: plant.level, earned: earned))
                                       : Self.label(name: plant.name, botanicalName: plant.botanicalName, level: plant.level, earned: earned))
    }

    static func label(name: String, botanicalName: String, level: Int, earned: Bool) -> String {
        earned ? "\(name), \(botanicalName)" : "Not found yet, level \(level)"
    }
}
