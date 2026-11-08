import SwiftUI
import GoogleMobileAds

/// The Garden's bottom banner slot (spec 1.3): the first Garden banner of an ad visit may be the collapsible one, every
/// later load and every refresh is the ordinary Garden banner (which reuses the Home unit), and the caption row sits
/// below as on Home. The slot takes the banner's real adaptive height (B4); the app draws nothing over the expanded ad.
struct GardenBannerSlot: View {
    @Environment(AppModel.self) private var app
    @Environment(GameRouter.self) private var router
    @Environment(\.dynamicTypeSize) private var typeSize
    @Binding var height: CGFloat
    /// Decided once when the slot appears: true = this banner view is created on the collapsible unit with the extras.
    @State private var collapsible: Bool?

    var body: some View {
        if app.showBanner && app.decide(.banner(.garden)).isYes && app.ads.started {
            VStack(spacing: 2) {
                Group {
                    if let collapsible {
                        GardenAdBanner(collapsible: collapsible, height: $height) { app.noteGardenBannerReceived(isCollapsible: $0) }
                    } else {
                        Color.clear
                    }
                }
                .frame(height: height)
                HStack(spacing: 16) {
                    Button(AdFormatCopy.Banner.goAdFree) { router.go(.plus) }
                    Link(AdFormatCopy.Banner.report, destination: Links.reportAd)
                }
                .font(Theme.font(.caption)).foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 4).frame(maxWidth: .infinity).background(Color.appBackground)
            .onAppear {
                if collapsible == nil { collapsible = app.requestCollapsibleIfEligible(accessibilityTextSize: typeSize.isAccessibilitySize) }
            }
        }
    }
}

/// The Garden banner. One `BannerView` has one unit id (option a): created on the collapsible unit when `collapsible`
/// (fallback chain collapsible, Garden, Home), it swaps in a second view on the Garden unit when the ad that came back
/// is not collapsible, when the collapsible ad is collapsed, or after the refresh interval. Auto-refresh therefore
/// never requests a collapsible ad, and no second collapsible request is made in the visit.
struct GardenAdBanner: UIViewRepresentable {
    let collapsible: Bool
    @Binding var height: CGFloat
    let onReceive: (Bool) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onReceive: onReceive, height: $height) }

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.accessibilityIdentifier = "gardenBanner"
        #if DEBUG
        if AdsService.debugFakeBanners {
            context.coordinator.attachFake(to: container, collapsible: collapsible)
            return container
        }
        #endif
        context.coordinator.attach(to: container, collapsible: collapsible)
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) { coordinator.stop() }

    @MainActor
    final class Coordinator: NSObject, BannerViewDelegate {
        private let onReceive: (Bool) -> Void
        private var height: Binding<CGFloat>
        private weak var container: UIView?
        private var current: BannerView?
        private var next: BannerView?
        private var requestedCollapsible = false
        private var swapped = false
        private var swapTask: Task<Void, Never>?

        init(onReceive: @escaping (Bool) -> Void, height: Binding<CGFloat>) { self.onReceive = onReceive; self.height = height }

        private func makeBanner(unit: AdUnit) -> BannerView {
            let b = BannerView(adSize: currentOrientationAnchoredAdaptiveBanner(width: AdBannerView.width))
            b.adUnitID = AdsService.unitID(unit)
            b.rootViewController = AdsService.rootViewController()
            b.delegate = self
            b.translatesAutoresizingMaskIntoConstraints = false
            return b
        }

        private func place(_ b: BannerView, in container: UIView) {
            container.addSubview(b)
            NSLayoutConstraint.activate([
                b.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                b.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            ])
            let h = b.adSize.size.height
            let binding = height
            DispatchQueue.main.async { binding.wrappedValue = h }
        }

        func attach(to container: UIView, collapsible: Bool) {
            self.container = container
            requestedCollapsible = collapsible
            let b = makeBanner(unit: collapsible ? .bannerGardenCollapsible : .bannerGarden)
            place(b, in: container)
            current = b
            let request = Request()
            if collapsible {
                let extras = Extras()
                extras.additionalParameters = ["collapsible": "bottom"]
                request.register(extras)
            }
            b.load(request)
        }

        /// Swaps in the ordinary Garden banner (refreshes on the console's 60 s); the old view stays until it fills.
        private func swapToGarden() {
            guard !swapped, let container else { return }
            swapped = true
            swapTask?.cancel()
            let b = makeBanner(unit: .bannerGarden)
            b.isHidden = true
            place(b, in: container)
            next = b
            b.load(Request())
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            if bannerView === next {
                bannerView.isHidden = false
                current?.removeFromSuperview()
                current = bannerView
                next = nil
                return
            }
            guard bannerView === current, !swapped else { return }
            let isCollapsible = bannerView.isCollapsible
            onReceive(isCollapsible)
            if CollapsibleRules.swapNow(requestedCollapsible: requestedCollapsible, isCollapsible: isCollapsible) {
                swapToGarden()
            } else if requestedCollapsible {
                swapTask = Task { @MainActor [weak self] in
                    try? await Task.sleep(nanoseconds: UInt64(CollapsibleRules.swapAfter * 1_000_000_000))
                    guard !Task.isCancelled else { return }
                    self?.swapToGarden()
                }
            }
        }

        /// The expanded collapsible ad was collapsed (or its overlay closed): hand over to the Garden unit.
        func bannerViewDidDismissScreen(_ bannerView: BannerView) {
            if bannerView === current, requestedCollapsible { swapToGarden() }
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            // A failed collapsible request falls back to the ordinary Garden banner once; a failed swap keeps the old view.
            if bannerView === current, requestedCollapsible, !swapped { swapToGarden() }
            if bannerView === next { bannerView.removeFromSuperview(); next = nil }
        }

        func stop() { swapTask?.cancel() }

        #if DEBUG
        /// `-uitest-ads-fake`: a plain labelled view instead of Google's banner. It says which path it took, and a
        /// collapsible fake counts as collapsible.
        func attachFake(to container: UIView, collapsible: Bool) {
            let label = UILabel()
            label.text = collapsible ? "Test banner, collapsible" : "Test banner"
            label.font = .preferredFont(forTextStyle: .caption1)
            label.adjustsFontForContentSizeCategory = true
            label.textAlignment = .center
            label.backgroundColor = .secondarySystemBackground
            label.translatesAutoresizingMaskIntoConstraints = false
            label.isAccessibilityElement = true
            label.accessibilityIdentifier = collapsible ? "gardenBanner.fake.collapsible" : "gardenBanner.fake.plain"
            container.addSubview(label)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                label.topAnchor.constraint(equalTo: container.topAnchor),
                label.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            ])
            let receive = onReceive
            DispatchQueue.main.async { receive(collapsible) }
        }
        #endif
    }
}

#if DEBUG
extension AdsService {
    /// `-uitest-ads-fake`: banners are plain labelled views (no Google request).
    static var debugFakeBanners: Bool { ProcessInfo.processInfo.arguments.contains("-uitest-ads-fake") }
}
#endif
