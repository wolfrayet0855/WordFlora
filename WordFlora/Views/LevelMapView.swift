import SwiftUI
import SwiftData

/// Two tracks per level (spec section 19, P-01): Word (10 plants earned) and Garden (all 10 flourishing).
struct LevelMapView: View {
    @Environment(AppModel.self) private var app
    @Environment(GameRouter.self) private var router
    @Query private var plants: [PlantCollectible]

    private let names = ["Seedling", "Sprout", "Bloom", "Grove", "Ancient"]

    var body: some View {
        let wordLevel = app.profile?.currentLevel ?? 1
        ScrollView {
            VStack(spacing: 14) {
                ForEach(1...5, id: \.self) { level in card(level: level, unlocked: level <= wordLevel, current: level == wordLevel) }
            }.padding(20)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Levels")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func card(level: Int, unlocked: Bool, current: Bool) -> some View {
        let inLevel = plants.filter { $0.level == level }
        let earned = inLevel.filter { $0.earnedCount > 0 }.count
        let flourishing = inLevel.filter { $0.stage >= 4 }.count
        return Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Level \(level) · \(names[level - 1])").font(Theme.font(.headline))
                    Spacer()
                    Image(systemName: unlocked ? (current ? "star.fill" : "checkmark.seal.fill") : "lock.fill")
                        .foregroundStyle(unlocked ? Color.appAccent : Color.appPrimaryText.opacity(0.35))
                }
                track("Words", value: earned, icon: "textformat.abc")
                track("Garden", value: flourishing, icon: "leaf.fill")
                if unlocked {
                    Button { router.go(.game(daily: false, level: level)) } label: { Label("Play level \(level)", systemImage: "play.fill") }
                        .buttonStyle(SecondaryButtonStyle())
                } else {
                    Text("Earn all 10 plants in level \(level - 1) to open this one.").font(Theme.font(.caption)).foregroundStyle(Color.secondaryText)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func track(_ title: String, value: Int, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundStyle(Color.successText).frame(width: 22)
            Text(title).font(Theme.font(.subheadline)).frame(width: 60, alignment: .leading)
            ProgressView(value: Double(value), total: 10).tint(Color.successText)
            Text("\(value)/10").font(Theme.font(.caption, weight: .semibold)).frame(width: 40, alignment: .trailing)
        }
        .frame(minHeight: Theme.minTap)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value) of 10")
    }
}
