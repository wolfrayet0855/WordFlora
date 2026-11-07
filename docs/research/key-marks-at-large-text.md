# Key marks (check / cross) at the largest Dynamic Type sizes

Scope: `WordFlora/Components/KeyboardView.swift` (the puzzle letter keyboard). Research only, no app code changed.
Tags: **[Apple]** = Apple-official docs, HIG, App Store Connect help or WWDC. **[Community]** = blogs, forums, Reddit, third parties. **[Inference]** = my reasoning, no source.

## 1. What the code does today

- Keys are width-driven: ten keys plus nine 5 pt gaps fill the row, so a key is about 30 pt wide on a 375 pt phone. Height is a fixed `keyHeight = 50`. Neither scales with text size.
- The letter is `Theme.font(.title3, weight: .bold)` with `lineLimit(1)` and `minimumScaleFactor(0.4)`, filling the whole key (`maxWidth/maxHeight: .infinity`).
- The mark is `Image(systemName: "checkmark"/"xmark")` at a fixed `PuzzleInk.usedGlyphSize = 11` pt, in a `ZStack(alignment: .topTrailing)` with 3 pt padding. It sits on top of the letter, so it overlaps the letter whenever the letter grows to fill the key (AX3-AX5, wide letters R, S, Z).
- VoiceOver label is a single string, `"R, in the word"` or `"R, not in the word"`. Used keys are `.disabled`.
- The mark is not decorative: colour is not the only signal, and the mark is the non-colour cue. Removing it requires another non-colour cue (section 3).
- Existing test hooks: `EndgameUITests.testThePuzzleAtAnAccessibilitySize` and the `-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXXXL` launch arguments (`GuideUITests.axText`). `ViewThatFits` is already avoided for this exact reason (see `FamilyShareNudgeRow.swift` comment).

## 2. Findings on Dynamic Type for fixed-size controls

1. Apple wants meaningful icons to grow with text: "Increase the size of meaningful interface icons as font size increases", and SF Symbols scale automatically. [Apple] https://developer.apple.com/design/human-interface-guidelines/typography (Supporting Dynamic Type)
2. Apple's stated fix for crowding is a layout change: when "inline items (like glyphs ...) and container boundaries can crowd text and cause truncation or overlapping", consider "a stacked layout where text appears above secondary items", and reduce columns. [Apple] same URL. A stacked letter-over-mark inside the key follows this advice and stays one layout.
3. Larger Text evaluation criteria: "Avoid overlapping text"; small side-by-side elements "may overlap when enlarged, so consider wrapping them onto a new line or laying them out vertically". Some elements, like tab bars, deliberately do not grow: "Consider other ways to make those elements accessible, such as the Large Content Viewer". Also says Dynamic Type exceeds 200% at AX3 and body text exceeds 300% at AX5. [Apple] https://developer.apple.com/help/app-store-connect/manage-app-accessibility/larger-text-evaluation-criteria
4. Apple says to prioritise scaling "main content areas before repeated, predictable navigational elements" (same page). A 26-key keyboard that must fit on a phone is the repeated, constrained case; the letter must stay readable but the key cannot grow without bounds. [Apple] [Inference on applying it to keys]
5. Capping: `dynamicTypeSize(_:)` accepts ranges (`...DynamicTypeSize.xxxLarge`); the five `accessibility` cases are "much larger than the rest" and `isAccessibilitySize` exists to adapt layout. [Apple] https://developer.apple.com/documentation/swiftui/dynamictypesize.md
6. Caps are for things that must stay small; do not use them to hide layout problems, and Apple's WWDC21 guidance is not to unduly restrict size. [Community summary of Apple guidance] https://useyourloaf.com/blog/restricting-dynamic-type-sizes/
7. If you cap, pair it with the Large Content Viewer. Apple: "Rely on the large content viewer only in situations where items must remain small due to unavoidable design constraints ... views that have their Dynamic Type size constrained with `dynamicTypeSize(_:)` may require a large content view", and "Don't use the large content viewer as a replacement for proper Dynamic Type support." [Apple] https://developer.apple.com/documentation/swiftui/view/accessibilityshowslargecontentviewer(_:).md . WWDC24 "Get started with Dynamic Type" says the viewer is for "controls that may not be able to grow with larger text sizes" and to adopt it for custom bars/views. [Apple] https://developer.apple.com/videos/play/wwdc2024/10074/ . Worked example of cap plus viewer: [Community] https://www.nilcoalescing.com/blog/LargeContentViewerInSwiftUI
8. `@ScaledMetric` scales non-text numbers (sizes, spacing, glyph size) with the text size; for assets, WWDC24 recommends it and says decorative views should be scaled less than essential ones. [Apple] https://developer.apple.com/videos/play/wwdc2024/10074/ . Usage: [Community] https://useyourloaf.com/blog/the-@scaledmetric-property-wrapper/
9. Fewer columns at large sizes is a recognised pattern (WWDC26 session mentions it). Not applicable to a QWERTY layout, which must stay 10 wide. [Apple, search snippet only, not read in full] https://developer.apple.com/videos/play/wwdc2026/221/
10. `minimumScaleFactor`: I found no Apple guidance on it for keys. [Inference] Shrinking each letter independently means W and I end at different sizes, and a letter can sit at 0.4x which is below Apple's 11 pt minimum for custom type (the HIG table gives iOS default 17 pt, minimum 11 pt: https://developer.apple.com/design/human-interface-guidelines/accessibility [Apple]). Single letters never truncate, so the scale factor is a safe last resort but should not be the main mechanism; give the letter a known box and let it scale only slightly.
11. Apple's own keyboard does not grow with Larger Text: user reports say bigger text does not make bigger keys on iPhone, and the keyboard bug on iPadOS 26 is an oversized keyboard, not a scaled one. [Community] https://discussions.apple.com/thread/256144824 , https://discussions.apple.com/thread/256144457 . I found no Apple statement on whether the system keyboard key pop-up is a Large Content Viewer feature. Treat "Apple's keyboard keeps fixed key size and shows a pop-up" as an observation, not a sourced fact.
12. Reddit: I could not retrieve a relevant r/iOSProgramming thread. One r/SwiftUI post (via a mirror) shows a label limited with `.dynamicTypeSize(.xxSmall ... .accessibility5)`: https://redlib.hbubli.cc/r/SwiftUI/comments/1l2cb5k/button_label [Community, weak]. A designer's notes recommend capping chrome while letting content scale: https://www.david-smith.org/blog/2022/12/19/design-notes-11/ [Community]

## 3. State markers: not colour alone, and not overlapping

- Apple: "Convey information with more than color alone ... Offer visual indicators, like distinct shapes or icons, in addition to color." Example of correct: green circle with checkmark plus red octagon with X. [Apple] https://developer.apple.com/design/human-interface-guidelines/accessibility.md
- App Store Connect "Differentiate Without Color Alone": use "placement, order, shape, iconography, or other stylistic differences in addition to color"; test in the Grayscale filter. [Apple] https://developer.apple.com/help/app-store-connect/manage-app-accessibility/differentiate-without-color-alone-evaluation-criteria
- So dropping the mark at AX sizes is allowed only if another non-colour cue replaces it. Options ranked for this key (30-35 pt wide, 50 pt tall):
  1. **Reserve a marker strip below the letter, same layout at every size (recommended).** The letter lives in the upper box, the mark in a fixed bottom strip. Nothing can overlap by construction, and it is the stacked layout Apple suggests. Cost: letter box is about 12-14 pt shorter; at default size title3 (about 20 pt) still fits in a 36 pt box.
  2. Corner badge outside the letter's box. Not feasible: a 30 pt wide key has no free corner once the letter fills it. [Inference]
  3. Shrink the mark only. Fails: the letter grows past any fixed corner, and marks under about 10 pt are not meaningful icons (Apple says icons that carry information must grow).
  4. Drop the mark at AX sizes and use a border/underline/pattern. Valid per Apple but creates two visual systems, and a cross-hatch or underline competes with the letter at its largest. Two states also need two distinct patterns. Keep as a fallback only.
- Grayscale already works: correct = solid fill, wrong = faded fill and faded letter, unused = outlined with lip. Keep the fills as a second cue behind the mark.
- Word games: Wordle's colour-blind option swaps green/yellow for orange/blue (a palette change, not a shape cue) [Community, secondhand] https://billfischer.substack.com/p/these-2-wordle-colors-undermine-color . Wordle clones announce tile letter and state to screen readers [Community] https://wordle.global/accessibility . I did not find reliable, current first-party evidence of how NYT Games, or any other word game, lays out key marks at AX sizes. I will not claim an industry norm; WordFlora's shape mark is already stronger than the palette-only approach.

## 4. VoiceOver for key states

- Apple: give custom elements labels, keep them up to date, and "Exclude purely decorative images from VoiceOver". [Apple] https://developer.apple.com/design/human-interface-guidelines/voiceover.md
- Today the label is built as `"R, in the word"`. Recommended shape: label is the letter only, state goes in `accessibilityValue` ("in the word" / "not in the word"). VoiceOver then reads "R, in the word", consistent with how controls expose state, and Voice Control users can still say "Tap R" because the label stays exactly the letter. [Inference on Voice Control; HIG says to label elements appropriately for Voice Control: https://developer.apple.com/design/human-interface-guidelines/accessibility.md , Apple]
- The mark image must be `accessibilityHidden(true)`; the value carries the meaning (it already is hidden by being inside the button's label, but make it explicit).
- Used keys are `.disabled`, so VoiceOver adds "dimmed". Acceptable, but if you want used keys to read as informational, keep them focusable (they are) and consider not disabling and ignoring taps instead. Low priority, test with a device. [Inference]
- Announce changes: the HIG says to "report visible changes" to VoiceOver ([Apple] voiceover.md above). A key turning correct/wrong after a guess is already covered if the tile/result announcement exists; verify it so users do not need to re-scan the keyboard. [Inference]

## 5. Recommendation (one layout, no ViewThatFits)

1. Put the letter and the mark in a vertical stack inside the key: letter box on top, fixed marker strip below. Always reserve the strip (also for unused keys) so a letter never jumps when its state changes.
2. Scale the key height modestly with `@ScaledMetric(relativeTo: .title3)` and clamp (for example 50 to 64 pt) so the keyboard does not eat the screen. Keys are width-limited, so only height can grow.
3. Cap the letter's Dynamic Type at `.accessibility1` or `.accessibility2` on keys only, scale the mark with `@ScaledMetric` but clamp it to the strip. Letter is still huge relative to default (Apple: AX3 is already over 200%).
4. Add `accessibilityShowsLargeContentViewer` with the letter and state because the key's size is constrained (Apple explicitly names this case).
5. Move state from label to `accessibilityValue`; hide the glyph from VoiceOver.
6. Do not rely on `minimumScaleFactor` for the main fit; keep it at about 0.7 as a safety net.

### SwiftUI sketch (fitted to the existing `key(_:width:)`)

```swift
struct KeyboardView: View {
    // ...existing properties...
    @ScaledMetric(relativeTo: .title3) private var keyHeight: CGFloat = 50
    @ScaledMetric(relativeTo: .caption2) private var markSize: CGFloat = 11

    private var height: CGFloat { min(keyHeight, 64) }          // keys can only grow vertically
    private var mark: CGFloat   { min(markSize, 14) }           // fits the strip
    private var strip: CGFloat  { mark + 2 }

    private func key(_ ch: Character, width: CGFloat) -> some View {
        let s = state(ch)
        let shape = RoundedRectangle(cornerRadius: 9)
        return Button { onTap(ch) } label: {
            VStack(spacing: 0) {
                Text(String(ch))
                    .font(Theme.font(.title3, weight: .bold))
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)   // cap on keys only
                    .lineLimit(1).minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                // The strip is always reserved, so the mark can never touch the letter.
                Group {
                    if s == .correct { Image(systemName: "checkmark") }
                    else if s == .wrong { Image(systemName: "xmark") }
                    else { Color.clear }
                }
                .font(.system(size: mark, weight: .black))
                .frame(height: strip)
                .accessibilityHidden(true)
            }
            .foregroundStyle(foreground(s))
            .frame(width: width, height: height)
            .background(background(s), in: shape)
            // ...existing overlay and shadow...
        }
        .buttonStyle(KeyPressStyle())
        .disabled(!enabled || s != .unused)
        .accessibilityLabel(String(ch))
        .accessibilityValue(s == .correct ? "in the word" : s == .wrong ? "not in the word" : "")
        .accessibilityShowsLargeContentViewer {
            Text(String(ch) + (s == .correct ? " \u{2713}" : s == .wrong ? " \u{2717}" : ""))
        }
    }
}
```

Notes on the sketch: `KeyboardLayout.keyHeight` is a static constant, so replace its use in `key` with the scaled `height`; check any other reader of `KeyboardLayout.keyHeight` (grep before changing). `PuzzleInk.usedGlyphSize` stays as the base value for `markSize`. Whether `accessibility2` is the right cap needs a visual check at AX3-AX5, because the cap makes AX3-AX5 render the same letter size (that is the intent: letter fits the box). If the user's text size is above the cap, the Large Content Viewer is the compensation; Apple documents exactly this pairing.

If a reviewer rejects the always-reserved strip (letter looks high at default size), the fallback is option 4: keep today's corner mark below `.accessibility1` (via `dynamicTypeSize < .accessibility1`, same layout tree with a conditional view, not a different container) and above it replace the mark with a bottom underline bar (correct: thick solid; wrong: dashed) plus the existing fills. That adds a second visual system and is why it is second choice.

## 6. What to verify (UI tests and screenshots)

Existing infrastructure: `EndgameUITests` (`audit(...)`, `shot(...)`, `Self.axSize`), `GuideUITests.axText` launch args, and `performAccessibilityAudit` via `audit`.

1. New UI test `testKeyboardMarksAtAX5`: launch with `UICTContentSizeCategoryAccessibilityXXXL`, then also `UICTContentSizeCategoryAccessibilityXL` (AX1) and default `Large`; guess letters so R, S, Z are correct or wrong (the failing letters); `audit()` on each. Run in light and dark (`testAuditTheNotebookAtAXXXLInDark` is the pattern).
2. Geometry assertion: for each guessed key, compare the frame of the mark element with the letter element. Give the mark an identifier (`key.R.mark`) and the letter text one (`key.R.letter`), but note they are inside a button. Assert `markFrame.minY >= letterFrame.maxY - 1` (no vertical overlap). The letter should keep a height of at least about 14 pt.
3. Hit target: every key frame width >= 28 pt and height >= 44 pt (Apple minimum control size is 28x28, default 44x44: https://developer.apple.com/design/human-interface-guidelines/accessibility.md). Keys are about 30 wide, so the 44 target is met only by height; this already passes.
4. VoiceOver strings: assert `key.label == "R"` and `key.value as? String == "in the word"` / `"not in the word"`; unused key has an empty value. Update the existing tests that read the old combined label (search `UITests` for `in the word` before changing).
5. Screenshots (use `shot`): default, AX1, AX3, AX5 x (light, dark, Increase Contrast) x (iPhone SE-width 375 and a Max-width) with keys R, S, Z, W, M, I in each of the three states. Add a Grayscale-filter pass by hand once (Apple's own test, see section 3).
6. Manual: long-press a key at AX5 with Larger Text on to confirm the Large Content Viewer shows letter and state; VoiceOver sweep over a row; Voice Control "Tap R".
7. Regression: keyboard height at AX5 against the rest of the puzzle screen (`GameView` already uses `isAccessibilitySize` for other spacing); the tiles and clue must not be pushed off screen at 64 pt rows (3 rows x 64 + 2 x 8 = 208 pt).

## 7. Top 5 summary

1. Keep one layout and give the mark its own space: a bottom strip under the letter (stacked), not a corner overlay. Apple's HIG suggests stacking glyphs and text at large sizes. https://developer.apple.com/design/human-interface-guidelines/typography [Apple]
2. Never drop the shape cue without a replacement: Apple requires more than colour (shape/icon, placement), tested in Grayscale. https://developer.apple.com/help/app-store-connect/manage-app-accessibility/differentiate-without-color-alone-evaluation-criteria [Apple]
3. Scale the mark and key height with `@ScaledMetric`, clamp both, and cap only the key letter's Dynamic Type; pair the cap with `accessibilityShowsLargeContentViewer` as Apple documents. https://developer.apple.com/documentation/swiftui/view/accessibilityshowslargecontentviewer(_:).md [Apple]; example https://www.nilcoalescing.com/blog/LargeContentViewerInSwiftUI [Community]
4. Letter in `accessibilityLabel`, state in `accessibilityValue`, mark hidden from VoiceOver. https://developer.apple.com/design/human-interface-guidelines/voiceover.md [Apple] (the label/value split itself is my inference)
5. Test AX1/AX3/AX5, light/dark, with a frame-overlap assertion for R, S, Z plus `performAccessibilityAudit`, since the earlier ViewThatFits attempt failed the iOS 26 audit. Apple's requirement: "Avoid overlapping text" and verify at the largest accessibility sizes. https://developer.apple.com/help/app-store-connect/manage-app-accessibility/larger-text-evaluation-criteria [Apple]

### Source gaps (be honest)
- No Apple source on `minimumScaleFactor` for keys, on the system keyboard's Large Content Viewer behaviour, or on how NYT Wordle or other word games place marks at AX sizes.
- Reddit coverage is one weak r/SwiftUI snippet; no relevant r/iOSProgramming thread was retrievable.
- Several Apple pages were read as markdown copies (`.md` URLs) of the live docs; the WWDC24 transcript was summarised by the fetch tool, not read verbatim.
