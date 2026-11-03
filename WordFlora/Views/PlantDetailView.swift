import SwiftUI
import TipKit
import SwiftData

struct PlantDetailView: View {
    let plantId: String

    @Environment(AppModel.self) private var app
    @State private var toast: String?
    @State private var sway = 0.0
    @State private var hellos = 0
    @State private var showRepot = false
    @State private var renaming = false
    @State private var draftName = ""
    @State private var bump = false
    @State private var aiText: String?
    @State private var aiBusy = false

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
                    if !quiet {          // a soft ring shows how much of today this plant has enjoyed; never a count
                        let fill = TendingEngine.capacityFill(plant, now: .now, calendar: .current, economy: .default)
                        Circle().stroke(Color.appSurface, lineWidth: 6).frame(width: 178, height: 178).frame(maxWidth: .infinity)
                            .overlay(Circle().trim(from: 0, to: fill).stroke(Color.accentText.opacity(0.85), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                .rotationEffect(.degrees(-90)).frame(width: 178, height: 178))
                            .animation(.easeInOut(duration: 0.5), value: fill)
                            .accessibilityHidden(true)
                    }
                    Image(plant.imageName).resizable().scaledToFit().frame(height: 156)
                        .rotationEffect(.degrees(thirsty ? 5 : sway), anchor: .bottom)
                        .onTapGesture {            // a small hello: the plant sways back and settles
                            hellos += 1
                            guard !UIAccessibility.isReduceMotionEnabled else { return }
                            withAnimation(.interpolatingSpring(stiffness: 90, damping: 5)) { sway = 7 }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { withAnimation(.interpolatingSpring(stiffness: 90, damping: 5)) { sway = 0 } }
                        }
                        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.5), trigger: hellos)
                        .modifier(HelloTipModifier())
                        .scaleEffect(bump ? 1.06 : 1)
                        .animation(.spring(response: 0.4, dampingFraction: 0.45), value: bump)
                        .accessibilityHidden(true)
                    if thirsty {
                        Image(systemName: "drop.fill").foregroundStyle(Color.successText).padding(10)
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
                    Text(plant.botanicalName).font(Theme.font(.subheadline)).italic().foregroundStyle(Color.secondaryText)
                    Text(thirsty ? "Thirsty. A drink will perk it right up." : Self.stageNames[min(4, plant.stage)])
                        .font(Theme.font(.callout, weight: .semibold)).foregroundStyle(Color.successText)
                }

                if !quiet { growthBar(plant); resources }

                actions(plant)

                if quiet {
                    Text("Take your time. Plants grow at their own pace.").font(Theme.font(.footnote)).foregroundStyle(Color.secondaryText)
                } else {
                    let cap = TendingEngine.capacityState(plant, now: .now, calendar: .current, economy: .default)
                    Label(TendingEngine.capacityLine(cap, name: plant.nickname.isEmpty ? plant.name : plant.nickname),
                          systemImage: cap == .plenty ? "checkmark.seal.fill" : "leaf.fill")
                        .font(Theme.font(.footnote, weight: .semibold)).foregroundStyle(Color.secondaryText).multilineTextAlignment(.center)
                }

                if app.canOfferRewarded && !quiet && (app.profile?.water ?? 0) == 0 {
                    Button { Task { if await app.watchRewardedAd() { run(.water, plant) } } } label: {
                        Label("Watch a short video for 2 drops", systemImage: "play.rectangle.fill")
                    }.buttonStyle(SecondaryButtonStyle())
                }

                Card { Text(plant.botanicalFact).font(Theme.font(.callout)).foregroundStyle(Color.appPrimaryText) }

                if GardenAIProvider.isModelBacked() {
                    if let aiText {
                        Card {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(aiText).font(Theme.font(.callout)).foregroundStyle(Color.appPrimaryText)
                                Label("Written by on-device AI", systemImage: "sparkles").font(Theme.font(.caption)).foregroundStyle(Color.secondaryText)
                            }
                        }
                    } else {
                        Button { Task { await tellMore(plant) } } label: { Label(aiBusy ? "Thinking…" : "Tell me more", systemImage: "sparkles") }
                            .buttonStyle(SecondaryButtonStyle()).disabled(aiBusy)
                    }
                }
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
            ProgressView(value: min(Double(plant.growthPoints), next), total: next).tint(Color.successText)
            HStack { ForEach(0..<5, id: \.self) { i in
                Circle().fill(i <= plant.stage ? Color.successText : Color.appPrimaryText.opacity(0.15)).frame(width: 8, height: 8)
            } }
        }
        .frame(minHeight: Theme.minTap)
        .contentShape(Rectangle())
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
            Text("Plants have favorite soils. Try one and see how it reacts.").font(Theme.font(.callout)).foregroundStyle(Color.secondaryText).multilineTextAlignment(.center)
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

    /// Grounded in the plant's reviewed fact; unsafe or empty output falls back to the fact itself (spec section 5).
    private func tellMore(_ plant: PlantCollectible) async {
        aiBusy = true
        let entry = WordEntry(id: plant.plantId, word: plant.name.uppercased().filter { $0.isLetter || $0 == " " }, display: plant.name, hint: "", hint2: nil,
                              fact: plant.botanicalFact, level: plant.level, kind: .vocab, plantId: nil, tags: [], minAge: 6, dailyEligible: false,
                              source: "bank", license: "proprietary", reviewedBy: nil)
        aiText = await GardenAIProvider.current().explain(entry: entry)
        aiBusy = false
    }

    private func run(_ action: AppModel.TendAction, _ plant: PlantCollectible) {
        let outcome = app.tend(action, plant: plant)
        if outcome.applied {
            switch action {
            case .water: app.play(.water)
            case .feed, .repot: app.play(.soil)
            case .sun: app.play(.sun)
            case .prune: app.play(.snip)
            }
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { toast = outcome.message }
        if outcome.stageUp { bump.toggle() }
        AccessibilityNotification.Announcement(outcome.message).post()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { withAnimation { toast = nil } }
    }
}

/// The "tap your plant" hint is hidden while VoiceOver runs, since the image is not a VoiceOver target.
private struct HelloTipModifier: ViewModifier {
    func body(content: Content) -> some View {
        if UIAccessibility.isVoiceOverRunning { content } else { content.popoverTip(PlantHelloTip(), arrowEdge: .bottom) }
    }
}
