import SwiftUI

struct PlantCard: View {
    let plant: PlantCollectible
    var compact = false

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
                    .accessibilityHidden(true)
                if !earned {
                    Image(systemName: "lock.fill").font(.caption2).foregroundStyle(Color.appPrimaryText.opacity(0.5)).padding(4)
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
        .padding(compact ? 8 : 12)
        .frame(maxWidth: .infinity)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(earned ? Color.appAccent.opacity(0.45) : Color.appPrimaryText.opacity(0.08)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(earned ? "\(plant.name), \(plant.botanicalName)" : "Locked plant, level \(plant.level)")
    }
}
