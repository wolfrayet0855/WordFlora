# R1 on the plant page after the engagement rebase: the same perk path as the Garden card (video, or free for Plus,
# under 13 and unknown age), sharing R1's three-a-day cap.
import sys, os
p = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.getcwd(), 'WordFlora/Views/PlantDetailView.swift')
s = open(p).read()
old = """        if app.canOfferRewarded && !quiet && (app.profile?.water ?? 0) == 0 {
            Button { Task { if await app.watchRewardedAd() { run(.water, kind: .water, plant) } } } label: {
                Label("Watch a short video for 2 drops", systemImage: "play.rectangle.fill")
            }.buttonStyle(SecondaryButtonStyle())
        }
"""
new = """        // R1: the perk path (video for 13 and over without Plus, the rain barrel for Plus, under 13 and unknown age).
        // The Garden card shares the same three-a-day cap. Quiet Garden never uses drops (the path is hidden there).
        if !quiet {
            RewardedPromptRow.forPath(app.perkPath(.water), adTitle: AdPerkCopy.Water.adTitle, freeTitle: AdPerkCopy.Water.freeTitle,
                                      hasPlus: app.entitlements.state.hasPlus, identifier: "plant.waterPerk") {
                Task { if await app.watchRewarded(.water) { run(.water, kind: .water, plant) } }
            }
        }
"""
assert s.count(old) == 1, "anchor moved"
s = s.replace(old, new)
open(p, 'w').write(s)
print("PlantDetailView patched")
