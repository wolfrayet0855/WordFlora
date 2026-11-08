import SwiftUI

struct PlantCard: View {
    let plant: PlantCollectible
    var compact = false
    /// In a garden row: stretch to the row's height so both cards in the row line up.
    var fillsHeight = false
    /// Pruning Pro: a faded bloom shows on this plant today (the only cue on the card: no badge, dot or number).
    var fadedBloom = false
    /// A found plant's card on its own (win, weather and first-word screens).
    var standalone = false

    @Environment(\.dynamicTypeSize) private var typeSize

    private var earned: Bool { plant.earnedCount > 0 }

    /// A found plant's card on its own (win, weather and first-word screens): 220 pt wide, the full width at the
    /// accessibility sizes so its name keeps whole words.
    static func foundWidth(_ size: DynamicTypeSize) -> CGFloat { size.isAccessibilitySize ? .infinity : 220 }

    /// The name: footnote on a compact card, and on a found plant's own card at the accessibility sizes (inside the
    /// dimmed card "Passionflower" does not fit in subheadline at AX4 and AX5); subheadline otherwise.
    static func nameStyle(_ size: DynamicTypeSize, compact: Bool, standalone: Bool) -> Font.TextStyle {
        compact || (standalone && size.isAccessibilitySize) ? .footnote : .subheadline
    }

    static func botanicalStyle(_ size: DynamicTypeSize) -> Font.TextStyle { size >= .xxxLarge ? .caption2 : .caption }

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
                .font(Theme.font(Self.nameStyle(typeSize, compact: compact, standalone: standalone), weight: .bold))
                .foregroundStyle(Color.appPrimaryText)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            if earned && !compact {
                // One step smaller from xxxLarge, so the longest Latin word ("pseudotruncatella") stays whole in two
                // columns and, at AX5, in one (TextFitLayoutTests).
                Text(plant.botanicalName).font(Theme.font(Self.botanicalStyle(typeSize))).italic()
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
