# Owner final checklist (owner-only, in order)

1. CloudKit schema. Why: the new fields (CD_lastMistedAt etc.) must exist in Production before the App Store build syncs.
   - Development run: Debug build signed into iCloud, buy Plus locally, play, Mist once. Steps: docs/setup/cloudkit-deploy-straight-to-prod.md part 2.
   - Deploy Development to Production: same file, part 3. Then verify the fields in the dashboard (CD_lastMistedAt).
   - Fill the deploy ledger in docs/setup/cloudkit-new-fields.md.
2. Art look. Why: the owner signs off the look before it ships.
   - Open http://127.0.0.1:8765/index.html. If the Mac rebooted: `python3 -m http.server 8765` from the review folder.
3. Stray xcscheme edit. Why: an uncommitted scheme change must not leak into the archive.
   - Decide keep or revert in the main checkout before archiving.
4. Archive and App Store Connect. Why: the shipped binary needs the real ad ids and a complete listing.
   - Archive from the MAIN checkout with Config/Ads.local.xcconfig present. The Release proof must pass.
   - pack_frost_lantern is done. Attach the build to the version.
   - Screenshots: docs/setup/screenshot-plan.md.
   - Privacy label: tick Developer Advertising and App Functionality. Steps: docs/setup/age-rating-and-privacy-label.md.
   - AdMob: GDPR and US state messages published; app-ads.txt live.
   - Review notes and other fields: docs/setup/owner-setup-steps.md, store text in docs/setup/store-listing.md.
5. Device checks. Why: only a real device proves widgets, audio and iCloud.
   - Part C of docs/pm/g6-device-checklist.md: widgets (13 items), audio, Settings and Restore, iCloud status, grown-up gates, weekly note, name your plant.
6. Offer codes (optional). Why: reviewer or friend access to Plus.
   - GARDENFRIEND and WELCOMEBACK, only if still wanted; paste one in the review notes if used.
7. Submit for review. Why: last step, after 1 to 6 are green.
   - Version page in App Store Connect > Add for Review > Submit. Release manually or automatically as you prefer.
