# Apply the G4a GameView edits (R2 hint row, B5 preload, whisper leaf dot) after the engagement rebase.
# Anchored by text; fails loudly if an anchor moved.
import sys, os
p = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.getcwd(), 'WordFlora/Views/GameView.swift')
s = open(p).read()
def rep(a, b):
    global s
    assert s.count(a) == 1, ("anchor", a[:80], s.count(a))
    s = s.replace(a, b)

# State
rep("""    @State private var adNoteOnOneMore = false
""", """    @State private var adNoteOnOneMore = false
    /// R2 on the resting card, captured as the card opens (and again after a hint video), like the ad note.
    @State private var hintPath: PerkPath = .hidden
    @State private var whisperOnCard = false
    @State private var watchingHint = false
    @State private var rewardToastText: String?
""")

# Help button: the leaf dot while a whisper is banked (hidden on the Daily Bloom and the tutorial by whisperReady)
rep("""            .background(Color.tileGardenFill, in: Capsule())
            // The capsule is 36 pt to look at; the hit area stays 44 pt.""",
"""            .background(Color.tileGardenFill, in: Capsule())
            .overlay(alignment: .topTrailing) {
                if vm.whisperReady {
                    Image(systemName: "leaf.fill").font(.caption2).foregroundStyle(Color.successText)
                        .offset(x: 2, y: -2).accessibilityHidden(true)
                        .accessibilityIdentifier("help.whisperDot")
                }
            }
            // The capsule is 36 pt to look at; the hit area stays 44 pt.""")
rep("""        .accessibilityHint("Gives a free clue")""",
"""        .accessibilityHint(vm.whisperReady ? AdPerkCopy.Hint.helpHint : "Gives a free clue")""")

# R2 row: below One more / That's enough, above the Go ad-free row
rep("""                    .padding(.top, 6)
                    if goAdFreeOnCard { goAdFreeRow.padding(.top, 2) }""",
"""                    .padding(.top, 6)
                    hintRow
                    if goAdFreeOnCard { goAdFreeRow.padding(.top, 2) }""")

# B5 preload + capture the hint path as the card opens
rep("""            adNoteOnOneMore = app.adWouldPlayOnOneMore
            goAdFreeOnCard = app.showBanner""",
"""            adNoteOnOneMore = app.adWouldPlayOnOneMore
            goAdFreeOnCard = app.showBanner
            whisperOnCard = app.whisperBanked
            hintPath = app.perkPath(.hint)
            // B5: the card says an ad may play, so load it now and "One more" never waits.
            if adNoteOnOneMore { Task { await app.ads.preloadInterstitial() } }""")

# hintRow view + toast: add before the tutorialEntry helper
rep("""    static func tutorialEntry(in bank: WordBank) -> WordEntry {""",
"""    /// R2 (docs/pm/admob-full-spec.md section 2, rulings): a whisper for the next garden word. Hidden after a loss, on
    /// the Daily Bloom card, in Quiet Garden for everyone, and while "A short ad may play first." shows; a banked whisper
    /// shows a line instead of a button.
    @ViewBuilder private var hintRow: some View {
        if whisperOnCard {
            Label(AdPerkCopy.Hint.banked, systemImage: "leaf.fill")
                .font(Theme.font(.footnote)).foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("restCard.whisperBanked")
        } else {
            RewardedPromptRow.forPath(hintPath, adTitle: AdPerkCopy.Hint.adTitle, freeTitle: AdPerkCopy.Hint.freeTitle,
                                      adSubtitle: AdPerkCopy.Hint.subtitle, freeSubtitle: AdPerkCopy.Hint.subtitle,
                                      hasPlus: app.entitlements.state.hasPlus, identifier: "restCard.hint", busy: watchingHint) {
                guard !watchingHint else { return }
                watchingHint = true
                Task {
                    if await app.watchRewarded(.hint) { rewardToastText = AdPerkCopy.Hint.toast }
                    // After a rewarded ad the gap holds the interstitial, so the note is worked out again (never lies).
                    adNoteOnOneMore = app.adWouldPlayOnOneMore
                    whisperOnCard = app.whisperBanked
                    hintPath = app.perkPath(.hint)
                    watchingHint = false
                }
            }
            .disabled(watchingHint)
        }
    }

    static func tutorialEntry(in bank: WordBank) -> WordEntry {""")
# The hint toast, on the resting card itself (it shows while the card is up).
rep("""            .accessibilityIdentifier("restCard")""",
"""            .accessibilityIdentifier("restCard")
            .rewardToast($rewardToastText)""")
open(p, 'w').write(s)
print("GameView patched (R2 row, B5 preload, whisper dot, hint toast)")
