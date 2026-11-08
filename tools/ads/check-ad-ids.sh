#!/bin/sh
# Check ad ids (WordFlora app target, Run Script build phase, after Info.plist is processed).
#
# Fails a RELEASE build when the built Info.plist would ship Google's test ad ids or a broken id:
#   - any of the nine AdMob unit keys or GADApplicationIdentifier is missing, empty or an unresolved $(...)
#   - any of them contains Google's test publisher number (this is what happens when Config/Ads.local.xcconfig,
#     which holds the real ids under [config=Release] and is git-ignored, is missing: Ads.xcconfig includes it
#     with #include?, so without it a Release build silently carries the test ids)
#   - a unit id is not ca-app-pub-<16 digits>/<10 digits>, or the app id is not ca-app-pub-<16 digits>~<10 digits>
# The Garden banner key equal to the Home banner key is allowed (reuse decision, 2026-11-07).
# Debug builds are skipped. Only key names and reasons are printed, never an id.
#
# Override: ADS_CHECK_SKIP=1 (environment or build setting) skips the check, but ONLY when CODE_SIGNING_ALLOWED=NO,
# i.e. an unsigned simulator proof build from a worktree, which never has the local file. A signed Release build
# (archive, TestFlight, App Store) can never skip it.
#   Example: ADS_CHECK_SKIP=1 xcodebuild -configuration Release CODE_SIGNING_ALLOWED=NO ...
set -u

stamp() { mkdir -p "${DERIVED_FILE_DIR}" && touch "${DERIVED_FILE_DIR}/ad-ids-checked"; }

[ "${CONFIGURATION:-}" = "Release" ] || { stamp; exit 0; }

if [ "${ADS_CHECK_SKIP:-0}" = "1" ]; then
  if [ "${CODE_SIGNING_ALLOWED:-YES}" = "NO" ]; then
    echo "warning: Check ad ids skipped (ADS_CHECK_SKIP=1 on an unsigned build). This build must never ship."
    stamp; exit 0
  fi
  echo "error: Check ad ids: ADS_CHECK_SKIP=1 is honoured only with CODE_SIGNING_ALLOWED=NO."
  exit 1
fi

PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
if [ ! -f "$PLIST" ]; then
  echo "error: Check ad ids: the built Info.plist was not found."
  exit 1
fi

TEST_PUB="3940256099942544"
UNIT_KEYS="AdMobBannerUnitID AdMobBannerGardenUnitID AdMobBannerGardenCollapsibleUnitID AdMobInterstitialUnitID AdMobRewardedUnitID AdMobRewardedHintUnitID AdMobRewardedWakeUnitID AdMobAppOpenUnitID AdMobNativeUnitID"
fail=0

check() { # key, regex
  v=$(/usr/libexec/PlistBuddy -c "Print :$1" "$PLIST" 2>/dev/null)
  if [ -z "$v" ]; then
    echo "error: Check ad ids: $1 is missing or empty in the Release Info.plist."; fail=1; return
  fi
  case "$v" in
    *'$('*) echo "error: Check ad ids: $1 is an unresolved build setting."; fail=1; return ;;
    *"$TEST_PUB"*) echo "error: Check ad ids: $1 is a Google test id in a Release build (is Config/Ads.local.xcconfig missing or incomplete?)."; fail=1; return ;;
  esac
  if ! printf '%s' "$v" | grep -Eq "$2"; then
    echo "error: Check ad ids: $1 does not have the shape of an AdMob id."; fail=1
  fi
}

for k in $UNIT_KEYS; do check "$k" '^ca-app-pub-[0-9]{16}/[0-9]{10}$'; done
check GADApplicationIdentifier '^ca-app-pub-[0-9]{16}~[0-9]{10}$'

if [ "$fail" -ne 0 ]; then
  echo "error: Check ad ids failed. Copy Config/Ads.local.xcconfig from the owner's checkout (never commit it), or for an unsigned simulator proof build set ADS_CHECK_SKIP=1 with CODE_SIGNING_ALLOWED=NO."
  exit 1
fi
stamp
echo "Check ad ids: Release ids present for the nine unit keys and the app id; no Google test id."
exit 0
