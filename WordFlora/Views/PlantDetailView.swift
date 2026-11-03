import SwiftUI
import SwiftData

struct PlantDetailView: View {
    let plantId: String

    @Environment(AppModel.self) private var app
    @State private var toast: String?
    @State private var showRepot = false
    @State private var renaming = false
    @State private var draftName = ""
    @State private var bump = false

    private var plant: PlantCollectible? { app.plants().first { $0.plantId == plantId } }
    private static let stageNames = ["Seed", "Sprout", "Bud", "Bloom", "Flourishing"]

    var body: some View {
        Group {
            if let plant { content(plant) } else { ComingSoonView(title: "Plant") }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(plant.map { $0.nickname.isEmpty ? $0.name : $0.nickname } ?? "Plant")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder private func content(_ plant: PlantCollectible) -> some View {
        let thirsty = TendingEngine.isThirsty(plant, now: .now, calm: app.settings.calmMode)
        let quiet = app.settings.quietGarden
        ScrollView {
            VStack(spacing: 16) {
                ZStack(alignment: .topTrailing) {
                    Image(plant.imageName).resizable().scaledToFit().frame(height: 190)
                        .rotationEffect(.degrees(thirsty ? 5 : 0), anchor: .bottom)
                        .scaleEffect(bump ? 1.06 : 1)
                        .animation(.spring(response: 0.4, dampingFraction: 0.45), value: bump)
                        .accessibilityHidden(true)
                    if thirsty {
                        Image(systemName: "drop.fill").foregroundStyle(Color.appSuccess).padding(10)
                            .background(Color.appSurface, in: Circle()).accessibilityLabel("Thirsty")
                    }
                }
                .frame(maxWidth: .infinity).padding(.top, 8)

                VStack(spacing: 4) {
                    Button { draftName = plant.nickname; renaming = true } label: {
                        HStack(spacing: 6) {
                            Text(plant.nickname.isEmpty ? plant.name : plant.nickname).font(Theme.font(.title2, weight: .bold))
                            Image(systemName: "pencil").font(.footnote)
                        }.foregroundStyle(Color.appPrimaryText)
                    }
                    .accessibilityHint("Give your plant a name")
                    Text(plant.botanicalName).font(Theme.font(.subheadline)).italic().foregroundStyle(Color.appPrimaryText.opacity(0.65))
                    Text(thirsty ? "Thirsty. A drink will perk it right up." : Self.stageNames[min(4, plant.stage)])
                        .font(Theme.font(.callout, weight: .semibold)).foregroundStyle(Color.appSuccess)
                }

                if !quiet { growthBar(plant) ; resources }

                actions(plant)

                Card { Text(plant.botanicalFact).font(Theme.font(.callout)).foregroundStyle(Color.appPrimaryText) }
            }
            .padding(20)
        }
        .overlay(alignment: .bottom) { toastView }
        .sheet(isPresented: $showRepot) { repotSheet(plant).presentationDetents([.medium]) }
        .alert("Name your plant", isPresented: $renaming) {
            TextField("Name", text: $draftName)
            Button("Save") { plant.nickname = String(draftName.prefix(16)); try? app.context.save() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func growthBar(_ plant: PlantCollectible) -> some View {
        let eco = Economy.default
        let cost = eco.levelBaseCost * eco.levelCostMultipliers[max(0, min(4, plant.level - 1))]
        let next = plant.stage >= 4 ? cost : (eco.stageThresholds[min(3, plant.stage)] * cost)
        return VStack(alignment: .leading, spacing: 6) {
            ProgressView(value: min(Double(plant.growthPoints), next), total: next).tint(Color.appSuccess)
            HStack { ForEach(0..<5, id: \.self) { i in
                Circle().fill(i <= plant.stage ? Color.appSuccess : Color.appPrimaryText.opacity(0.15)).frame(width: 8, height: 8)
            } }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Growth: \(Self.stageNames[min(4, plant.stage)]), stage \(plant.stage + 1) of 5")
    }

    private var resources: some View {
        let p = app.profile
        return HStack(spacing: 10) {
            chip("drop.fill", p?.water ?? 0, "water drops")
            chip("shippingbox.fill", p?.soil ?? 0, "soil scoops")
            chip("star.fill", p?.shedPoints ?? 0, "shed points")
        }
    }

    private func chip(_ icon: String, _ n: Int, _ label: String) -> some View {
        Label("\(n)", systemImage: icon).font(Theme.font(.subheadline, weight: .semibold))
            .padding(.horizontal, 12).frame(minHeight: 36).background(Color.appSurface, in: Capsule())
            .accessibilityLabel("\(n) \(label)")
    }

    private func actions(_ plant: PlantCollectible) -> some View {
        let owns = app.inventory
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            action("Water", "drop.fill") { run(.water, plant) }
            action("Feed", "leaf.arrow.triangle.circlepath") { run(.feed, plant) }
            action("Sun", "sun.max.fill") { run(.sun, plant) }
            if owns.tier(of: .shears) > 0 || app.settings.showEverything { action("Prune", "scissors") { run(.prune, plant) } }
            action("Repot", "shippingbox") { showRepot = true }
        }
    }

    private func action(_ title: String, _ icon: String, _ tap: @escaping () -> Void) -> some View {
        Button(action: tap) { Label(title, systemImage: icon) }.buttonStyle(SecondaryButtonStyle())
    }

    private func repotSheet(_ plant: PlantCollectible) -> some View {
        VStack(spacing: 14) {
            Text("Choose a soil").font(Theme.font(.title3, weight: .bold))
            Text("Plants have favourite soils. Try one and see how it reacts.").font(Theme.font(.callout)).foregroundStyle(Color.appPrimaryText.opacity(0.75)).multilineTextAlignment(.center)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(SoilType.allCases, id: \.self) { soil in
                    Button { showRepot = false; run(.repot(soil), plant) } label: { Text(soil.rawValue.capitalized) }
                        .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
        .padding(24)
    }

    @ViewBuilder private var toastView: some View {
        if let toast {
            Text(toast).font(Theme.font(.subheadline, weight: .semibold)).foregroundStyle(Color.appPrimaryText)
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(Color.appSurface, in: Capsule()).shadow(radius: 6, y: 2).padding(.bottom, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .accessibilityAddTraits(.updatesFrequently)
        }
    }

    private func run(_ action: AppModel.TendAction, _ plant: PlantCollectible) {
        let outcome = app.tend(action, plant: plant)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { toast = outcome.message }
        if outcome.stageUp { bump.toggle() }
        AccessibilityNotification.Announcement(outcome.message).post()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { withAnimation { toast = nil } }
    }
}
