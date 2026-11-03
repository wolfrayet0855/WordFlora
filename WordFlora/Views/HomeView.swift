import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var app
    @Environment(GameRouter.self) private var router

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

                HStack(spacing: 12) {
                    Button { router.go(.garden) } label: { Label("Garden", systemImage: "leaf.fill") }
                        .buttonStyle(SecondaryButtonStyle())
                    if app.isUnlocked(.butterfly) {
                        Button { router.go(.levelMap) } label: { Label("Levels", systemImage: "map.fill") }
                            .buttonStyle(SecondaryButtonStyle())
                    }
                }
                HStack(spacing: 12) {
                    if app.isUnlocked(.shed) {
                        Button { router.go(.shed) } label: { Label("Shed", systemImage: "wrench.and.screwdriver.fill") }
                            .buttonStyle(SecondaryButtonStyle())
                    }
                    if app.isUnlocked(.butterfly) {
                        Button { router.go(.butterfly) } label: { Label("Visitors", systemImage: "ladybug.fill") }
                            .buttonStyle(SecondaryButtonStyle())
                    }
                    if app.isUnlocked(.badges) {
                        Button { router.go(.badges) } label: { Label("Badges", systemImage: "rosette") }
                            .buttonStyle(SecondaryButtonStyle())
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) { bannerArea }
        .task { await app.prepareBannerIfAllowed() }
        .navigationBarHidden(true)
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
                    Text(streak > 1 ? "Streak \(streak)" : "Streak resting - your best was \(max(best, streak))")
                        .font(Theme.font(.caption)).foregroundStyle(Color.secondaryText).lineLimit(2)
                }
            }
        }
        .padding(10).frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .accessibilityElement(children: .combine)
    }
}
