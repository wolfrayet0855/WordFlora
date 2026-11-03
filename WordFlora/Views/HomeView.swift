import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var app
    @Environment(GameRouter.self) private var router

    /// Every destination is visible. Ones that are not open yet are dimmed with a kind line on how to reach them.
    @ViewBuilder private func featureTile(_ feature: Feature?, _ title: String, _ icon: String, _ route: GameRoute) -> some View {
        let open = feature.map { app.isUnlocked($0) } ?? true
        VStack(spacing: 4) {
            Button { router.go(route) } label: { Label(title, systemImage: icon) }
                .buttonStyle(SecondaryButtonStyle()).disabled(!open)
            if !open, let f = feature, let hint = FeatureUnlockPolicy.hint(for: f) {
                Text(hint).font(Theme.font(.caption)).foregroundStyle(Color.secondaryText).multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
    }

    var body: some View {
        let profile = app.profile
        ScrollView {
            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    Button { router.go(.settings) } label: {
                        Image(systemName: "gearshape.fill").font(.title3).frame(width: Theme.minTap, height: Theme.minTap)
                    }
                    .foregroundStyle(Color.secondaryText)
                    .accessibilityLabel("Settings")
                }

                VStack(spacing: 4) {
                    WordmarkView()
                    Text("Guess words. Grow a garden.")
                        .font(Theme.font(.callout, weight: .medium))
                        .foregroundStyle(Color.secondaryText)
                }

                if app.showWelcomeBack {
                    Card {
                        HStack(spacing: 10) {
                            Image(systemName: "cloud.sun.rain.fill").font(.title2).foregroundStyle(Color.accentText)
                            Text(app.welcomeLine).font(Theme.font(.callout)).foregroundStyle(Color.appPrimaryText).fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                            Button { app.dismissWelcomeBack() } label: { Image(systemName: "xmark").frame(width: Theme.minTap, height: Theme.minTap) }
                                .accessibilityLabel("Dismiss")
                        }
                    }
                    .transition(.opacity)
                }

                if app.plusOffer != nil { plusOfferCard.transition(.opacity) }

                FlowerView(petals: 8)
                    .frame(height: 220)
                    .padding(.vertical, 4)

                HStack(alignment: .top, spacing: 12) {
                    RoseSeedChip(progress: profile?.roseSeedProgress ?? 0, stock: profile?.roseOfJerichoCount ?? 0)
                    GardenDaysChip(days: profile?.gardenDays ?? 0,
                                   streak: app.settings.showStreak ? (profile?.streak ?? 0) : nil,
                                   best: profile?.bestStreak ?? 0)
                }

                Button { router.go(.game(daily: false, level: nil)) } label: {
                    Label("Play", systemImage: "play.fill")
                }
                .buttonStyle(PrimaryButtonStyle())

                if app.isUnlocked(.dailyBloom) {
                    let done = app.dailyBloomDoneToday
                    Button { router.go(.game(daily: true, level: nil)) } label: {
                        HStack {
                            Image(systemName: done ? "checkmark.circle.fill" : "sun.max.fill").foregroundStyle(done ? Color.successText : Color.accentText)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Daily Bloom").font(Theme.font(.headline))
                                Text(done ? "Done for today. See you tomorrow!" : "One word for everyone today").font(Theme.font(.caption)).foregroundStyle(Color.secondaryText)
                            }
                            Spacer()
                            if !done { Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Color.appPrimaryText.opacity(0.4)) }
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle()).disabled(done)
                }

                HStack(alignment: .top, spacing: 12) {
                    featureTile(nil, "Garden", "leaf.fill", .garden)
                    featureTile(.butterfly, "Levels", "map.fill", .levelMap)
                }
                HStack(alignment: .top, spacing: 12) {
                    featureTile(.shed, "Shed", "wrench.and.screwdriver.fill", .shed)
                    featureTile(.butterfly, "Visitors", "ladybug.fill", .butterfly)
                    featureTile(.badges, "Badges", "rosette", .badges)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) { bannerArea }
        .task { await app.prepareBannerIfAllowed() }
        .onAppear { app.checkPlusOffer() }
        .navigationBarHidden(true)
    }

    /// One gentle, dismissible card after a milestone (PlusOfferPolicy decides when).
    private var plusOfferCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "icloud.fill").font(.title2).foregroundStyle(Color.accentText)
                    Text(PlusOfferPolicy.Copy.headline).font(Theme.font(.headline)).foregroundStyle(Color.appPrimaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Button { withAnimation { app.dismissPlusOffer() } } label: { Image(systemName: "xmark").frame(width: Theme.minTap, height: Theme.minTap) }
                        .accessibilityLabel("Dismiss")
                }
                Text(PlusOfferPolicy.Copy.detail).font(Theme.font(.callout)).foregroundStyle(Color.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Button(PlusOfferPolicy.Copy.button) { app.dismissPlusOffer(); router.go(.plus) }
                    .font(Theme.font(.callout, weight: .semibold))
            }
        }
        .accessibilityIdentifier("plus-offer-card")
    }

    @ViewBuilder private var bannerArea: some View {
        if app.showBanner && app.ads.started {
            VStack(spacing: 2) {
                AdBannerView().frame(height: 60)
                HStack(spacing: 16) {
                    Button("Go ad-free") { router.go(.plus) }
                    Link("Report an ad", destination: Links.reportAd)
                }.font(Theme.font(.caption)).foregroundStyle(Color.secondaryText)
            }
            .padding(.vertical, 4).frame(maxWidth: .infinity).background(Color.appBackground)
        }
    }
}

struct RoseSeedChip: View {
    let progress: Int
    let stock: Int
    private let threshold = Economy.default.roseThreshold
    private var full: Bool { stock >= Economy.default.roseCap }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().stroke(Color.appPrimaryText.opacity(0.12), lineWidth: 5)
                Circle().trim(from: 0, to: full ? 1 : CGFloat(progress) / CGFloat(threshold))
                    .stroke(Color.successText, style: StrokeStyle(lineWidth: 5, lineCap: .round)).rotationEffect(.degrees(-90))
                Image("rose_of_jericho").resizable().scaledToFit().padding(8)
            }
            .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 1) {
                Text("×\(stock)").font(Theme.font(.headline)).foregroundStyle(Color.appPrimaryText)
                Text(full ? "Your satchel is full" : "\(progress) of \(threshold)").font(Theme.font(.caption)).foregroundStyle(Color.secondaryText).fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10).frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rose of Jericho: \(stock) in your satchel, \(full ? "satchel full" : "\(progress) of \(threshold) rounds toward the next")")
    }
}

struct GardenDaysChip: View {
    let days: Int
    let streak: Int?
    let best: Int

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "calendar").font(.title3).foregroundStyle(Color.appAccent).frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 1) {
                Text(days == 0 ? "Your garden is new" : "\(days) Garden \(days == 1 ? "Day" : "Days")")
                    .font(Theme.font(.headline)).foregroundStyle(Color.appPrimaryText)
                if let streak, days > 0 {
                    Text(streak > 1 ? "Streak \(streak)" : "Best streak: \(max(best, streak))")
                        .font(Theme.font(.caption)).foregroundStyle(Color.secondaryText).lineLimit(2)
                }
            }
        }
        .padding(10).frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .accessibilityElement(children: .combine)
    }
}
