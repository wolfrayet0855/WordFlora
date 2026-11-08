import SwiftUI
import GoogleMobileAds

/// The Shed's "SPONSORED" section (spec 1.4): at the bottom of the Shed, after the pots, a header, one line and one
/// native card. Shows nothing at all (not even the header) unless an ad is loaded and every rule allows it, so under 13,
/// an unknown age and Plus never see it.
struct ShedSponsoredSection: View {
    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    var body: some View {
        // A VStack, not a Group: with no card yet a Group is empty and its `.task` (the load) would never run.
        VStack(alignment: .leading, spacing: 0) {
            Color.clear.frame(height: 0).accessibilityHidden(true)
            if app.shedShowsSponsored(reduceMotion: systemReduceMotion), let content = app.adFormats.nativeContent {
                VStack(alignment: .leading, spacing: Space.m) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(AdFormatCopy.Native.header.uppercased())
                            .font(Theme.font(.footnote, weight: .heavy)).tracking(1.2).foregroundStyle(Color.secondaryText)
                            .accessibilityLabel(AdFormatCopy.Native.header).accessibilityAddTraits(.isHeader)
                        Text(AdFormatCopy.Native.line)
                            .font(Theme.font(.subheadline)).foregroundStyle(Color.secondaryText)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    NativeAdCard(content: content)
                }
                .padding(.top, Space.section)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("shed.sponsored")
            }
        }
        .task { await app.loadNativeIfEligible(reduceMotion: systemReduceMotion) }
        .onChange(of: app.adTreatment) { _, _ in app.adFormatsTreatmentCheck() }
    }
}

/// The SwiftUI side of the card. Reads the text size so the UIKit card is measured again when it changes.
struct NativeAdCard: View {
    let content: NativeAdContent
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        NativeAdCardView(content: content, typeSize: typeSize, dark: scheme == .dark)
            .accessibilityIdentifier("nativeAdCard")         // the same id as the UIKit card, whichever one the tree shows
    }
}

/// A UIKit `NativeAdView` (asset views must be registered with it) in a representable. Flat muted fill, 1 pt border,
/// radius 12: deliberately not the game's card, tile or pot style. "Ad" badge top-left, AdChoices top-right with
/// nothing over it, icon and headline, a 16:9 media view (120 pt at least), body, stars and store, and an outlined
/// call to action. Scaled fonts that follow the text size, nothing truncated, one layout at every size.
struct NativeAdCardView: UIViewRepresentable {
    let content: NativeAdContent
    var typeSize: DynamicTypeSize
    var dark: Bool

    func makeUIView(context: Context) -> NativeAdCardUIView { NativeAdCardUIView() }

    func updateUIView(_ view: NativeAdCardUIView, context: Context) {
        view.apply(content)
        view.invalidateIntrinsicContentSize()
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: NativeAdCardUIView, context: Context) -> CGSize? {
        let width = proposal.width ?? (UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first?
            .keyWindow?.bounds.width ?? 390) - 2 * Space.gutter
        let fit = uiView.systemLayoutSizeFitting(CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
                                                 withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        return CGSize(width: width, height: ceil(fit.height))
    }
}

/// The card itself. Only the asset views are clickable (the SDK handles the taps on registered assets); the card's
/// background and the badge are not, and no app control sits over any asset.
final class NativeAdCardUIView: NativeAdView {
    private let badge = PaddedLabel()
    private let advertiser = UILabel()
    private let icon = UIImageView()
    private let headline = UILabel()
    private let media = MediaView()
    private let fakeMedia = UILabel()
    private let body = UILabel()
    private let storeLine = UILabel()
    private let cta = UIButton(type: .system)
    private let choices = AdChoicesView()
    private var mediaHeight: NSLayoutConstraint?

    static let fillLight = UIColor(hex: 0xF1EEE6)
    static let fillDark = UIColor(hex: 0x22362A)
    static let borderAlpha: CGFloat = 0.24

    private var ink: UIColor { UIColor(named: "appPrimaryText") ?? .label }

    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }

    required init?(coder: NSCoder) { fatalError("not used") }

    private static func font(_ style: UIFont.TextStyle, size: CGFloat, weight: UIFont.Weight) -> UIFont {
        var f = UIFont.systemFont(ofSize: size, weight: weight)
        if let d = f.fontDescriptor.withDesign(.rounded) { f = UIFont(descriptor: d, size: size) }
        return UIFontMetrics(forTextStyle: style).scaledFont(for: f)
    }

    private func style(_ l: UILabel, _ style: UIFont.TextStyle, size: CGFloat, weight: UIFont.Weight, alpha: CGFloat = 1) {
        l.font = Self.font(style, size: size, weight: weight)
        l.adjustsFontForContentSizeCategory = true
        l.numberOfLines = 0
        l.lineBreakMode = .byWordWrapping
        l.textColor = ink.withAlphaComponent(alpha)
        l.translatesAutoresizingMaskIntoConstraints = false
    }

    private func build() {
        layer.cornerRadius = 12
        layer.borderWidth = 1
        clipsToBounds = true
        backgroundColor = UIColor { $0.userInterfaceStyle == .dark ? Self.fillDark : Self.fillLight }

        style(badge, .caption1, size: 13, weight: .heavy)
        badge.text = AdFormatCopy.Native.badge
        badge.textAlignment = .center
        badge.backgroundColor = ink
        badge.layer.cornerRadius = 5
        badge.clipsToBounds = true
        badge.isAccessibilityElement = true
        badge.accessibilityLabel = AdFormatCopy.Native.badgeLabel
        badge.setContentHuggingPriority(.required, for: .horizontal)
        badge.setContentCompressionResistancePriority(.required, for: .horizontal)

        style(advertiser, .footnote, size: 13, weight: .semibold, alpha: 0.88)
        style(headline, .headline, size: 17, weight: .semibold)
        style(body, .subheadline, size: 15, weight: .regular, alpha: 0.88)
        style(storeLine, .footnote, size: 13, weight: .regular, alpha: 0.88)

        icon.contentMode = .scaleAspectFit
        icon.layer.cornerRadius = 8
        icon.clipsToBounds = true
        icon.translatesAutoresizingMaskIntoConstraints = false

        media.contentMode = .scaleAspectFit
        media.translatesAutoresizingMaskIntoConstraints = false
        fakeMedia.translatesAutoresizingMaskIntoConstraints = false
        fakeMedia.textAlignment = .center
        style(fakeMedia, .footnote, size: 13, weight: .semibold, alpha: 0.88)
        fakeMedia.textAlignment = .center

        var config = UIButton.Configuration.plain()
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        config.titleAlignment = .center
        config.titleLineBreakMode = .byWordWrapping
        cta.configuration = config
        cta.layer.cornerRadius = 12
        cta.layer.borderWidth = 1.5
        cta.translatesAutoresizingMaskIntoConstraints = false
        cta.isUserInteractionEnabled = false                       // the SDK handles the tap on the registered view
        cta.titleLabel?.numberOfLines = 0

        choices.translatesAutoresizingMaskIntoConstraints = false

        let topRow = UIStackView(arrangedSubviews: [badge, advertiser])
        topRow.axis = .horizontal; topRow.alignment = .firstBaseline; topRow.spacing = 8
        let iconRow = UIStackView(arrangedSubviews: [icon, headline])
        iconRow.axis = .horizontal; iconRow.alignment = .top; iconRow.spacing = 12
        let stack = UIStackView(arrangedSubviews: [topRow, iconRow, media, body, storeLine, cta])
        stack.axis = .vertical; stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        addSubview(choices)
        media.addSubview(fakeMedia)

        let mh = media.heightAnchor.constraint(equalTo: media.widthAnchor, multiplier: 9.0 / 16.0)
        mh.priority = .defaultHigh
        mediaHeight = mh
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            // The top row leaves room for AdChoices at the top-right, so nothing ever overlaps it.
            topRow.trailingAnchor.constraint(lessThanOrEqualTo: choices.leadingAnchor, constant: -8),
            choices.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            choices.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            choices.widthAnchor.constraint(equalToConstant: 24),
            choices.heightAnchor.constraint(equalToConstant: 24),
            badge.heightAnchor.constraint(greaterThanOrEqualToConstant: 20),
            badge.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
            icon.widthAnchor.constraint(equalToConstant: 40),
            icon.heightAnchor.constraint(equalToConstant: 40),
            mh,
            media.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),
            fakeMedia.centerXAnchor.constraint(equalTo: media.centerXAnchor),
            fakeMedia.centerYAnchor.constraint(equalTo: media.centerYAnchor),
            fakeMedia.leadingAnchor.constraint(greaterThanOrEqualTo: media.leadingAnchor, constant: 8),
            cta.heightAnchor.constraint(greaterThanOrEqualToConstant: 48),
        ])
        stack.setCustomSpacing(16, after: body)

        headlineView = headline
        advertiserView = advertiser
        iconView = icon
        mediaView = media
        bodyView = body
        storeView = storeLine
        callToActionView = cta
        adChoicesView = choices

        // VoiceOver: Ad badge, advertiser, headline, media, body, call to action, AdChoices.
        accessibilityContainerType = .semanticGroup
        media.isAccessibilityElement = true
        cta.isAccessibilityElement = true
        cta.accessibilityTraits = .button
        accessibilityElements = [badge, advertiser, headline, media, body, storeLine, cta, choices]
        accessibilityIdentifier = "nativeAdCard"
        applyColors()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyColors()
    }

    private func applyColors() {
        let ink = self.ink.resolvedColor(with: traitCollection)
        layer.borderColor = ink.withAlphaComponent(Self.borderAlpha).cgColor
        cta.layer.borderColor = ink.withAlphaComponent(0.5).cgColor
        badge.backgroundColor = ink
        badge.textColor = (UIColor(named: "appBackground") ?? .systemBackground).resolvedColor(with: traitCollection)
        for l in [advertiser, body, storeLine, fakeMedia] { l.textColor = ink.withAlphaComponent(0.88) }
        headline.textColor = ink
        media.backgroundColor = ink.withAlphaComponent(0.06)
    }

    func apply(_ c: NativeAdContent) {
        advertiser.text = c.advertiser
        advertiser.isHidden = c.advertiser.isEmpty
        headline.text = c.headline
        icon.image = c.icon
        icon.isHidden = c.icon == nil
        body.text = c.body
        body.isHidden = c.body.isEmpty
        var store = c.store
        if let stars = c.starRating { store = store.isEmpty ? "\(stars) stars" : "\(store) · \(stars) stars" }
        storeLine.text = store
        storeLine.isHidden = store.isEmpty
        var title = AttributedString(c.callToAction)
        title.font = Self.font(.body, size: 17, weight: .semibold)
        title.foregroundColor = ink
        cta.configuration?.attributedTitle = title
        cta.accessibilityLabel = c.callToAction
        cta.isHidden = c.callToAction.isEmpty
        if let ad = c.ad {
            fakeMedia.isHidden = true
            media.mediaContent = ad.mediaContent
            media.accessibilityLabel = c.hasVideo ? "Video" : "Image"
            nativeAd = ad                                                     // registers the asset views
        } else {
            // The Debug fake: drawn by the same card, never registered with Google.
            fakeMedia.isHidden = false
            fakeMedia.text = c.hasVideo ? "Test video" : "Test image"
            media.accessibilityLabel = fakeMedia.text
        }
        accessibilityLabel = AdFormatCopy.Native.groupLabel(headline: c.headline)
    }
}

/// A label with room around its text (the "Ad" badge).
final class PaddedLabel: UILabel {
    var insets = UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)
    override func drawText(in rect: CGRect) { super.drawText(in: rect.inset(by: insets)) }
    override var intrinsicContentSize: CGSize {
        let s = super.intrinsicContentSize
        return CGSize(width: s.width + insets.left + insets.right, height: s.height + insets.top + insets.bottom)
    }
}
