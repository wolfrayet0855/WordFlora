#!/bin/zsh
# Self-test for check-ad-ids.sh against fake Info.plists (synthetic ids only, never a real one).
# Usage: zsh tools/ads/check-ad-ids-test.sh   (exit 0 when every case gives the expected result)
SCRIPT=${0:A:h}/check-ad-ids.sh
S=$(mktemp -d)
trap 'rm -rf $S' EXIT
mkdir -p $S/app
KEYS=(AdMobBannerUnitID AdMobBannerGardenUnitID AdMobBannerGardenCollapsibleUnitID AdMobInterstitialUnitID AdMobRewardedUnitID AdMobRewardedHintUnitID AdMobRewardedWakeUnitID AdMobAppOpenUnitID AdMobNativeUnitID)
P=$S/app/Info.plist
mk() { # publisher number
  rm -f $P
  /usr/libexec/PlistBuddy -c "Add :GADApplicationIdentifier string ca-app-pub-$1~1234567890" $P >/dev/null
  local i=1
  for k in $KEYS; do /usr/libexec/PlistBuddy -c "Add :$k string ca-app-pub-$1/12345678$i$i" $P >/dev/null; i=$(( i < 9 ? i + 1 : 9 )); done
}
run() { env -i PATH=/usr/bin:/bin CONFIGURATION=$1 TARGET_BUILD_DIR=$S INFOPLIST_PATH=app/Info.plist DERIVED_FILE_DIR=$S/d ${=2} /bin/sh $SCRIPT >/dev/null 2>&1; echo $?; }
fails=0
expect() { # name expected actual
  if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1 (expected $2, got $3)"; fails=$((fails + 1)); fi
}
TEST=3940256099942544; FAKE=1111222233334444
mk $TEST; expect "Release with test ids fails" 1 $(run Release)
expect "Debug is skipped" 0 $(run Debug)
expect "skip on an unsigned local build" 0 $(run Release 'ADS_CHECK_SKIP=1 CODE_SIGNING_ALLOWED=NO')
expect "skip refused on a signed build" 1 $(run Release 'ADS_CHECK_SKIP=1')
expect "skip refused on an unsigned archive" 1 $(run Release 'ADS_CHECK_SKIP=1 CODE_SIGNING_ALLOWED=NO ACTION=install')
expect "skip refused for ACTION=archive" 1 $(run Release 'ADS_CHECK_SKIP=1 CODE_SIGNING_ALLOWED=NO ACTION=archive')
expect "archive with test ids fails" 1 $(run Release 'ACTION=install')
mk $FAKE; expect "real-shaped ids pass" 0 $(run Release)
expect "real-shaped ids pass in an archive" 0 $(run Release 'ACTION=install')
/usr/libexec/PlistBuddy -c "Set :AdMobBannerGardenUnitID $(/usr/libexec/PlistBuddy -c 'Print :AdMobBannerUnitID' $P)" $P
expect "Garden equal to Home is allowed" 0 $(run Release)
mk $FAKE; /usr/libexec/PlistBuddy -c "Set :AdMobNativeUnitID ''" $P; expect "an empty id fails" 1 $(run Release)
mk $FAKE; /usr/libexec/PlistBuddy -c 'Set :AdMobAppOpenUnitID $(ADMOB_APPOPEN_ID)' $P; expect "an unresolved id fails" 1 $(run Release)
mk $FAKE; /usr/libexec/PlistBuddy -c "Set :GADApplicationIdentifier ca-app-pub-$FAKE/1234567890" $P; expect "a slash app id fails" 1 $(run Release)
mk $FAKE; /usr/libexec/PlistBuddy -c 'Delete :AdMobRewardedWakeUnitID' $P; expect "a missing key fails" 1 $(run Release)
mk $TEST; out=$(env -i PATH=/usr/bin:/bin CONFIGURATION=Release TARGET_BUILD_DIR=$S INFOPLIST_PATH=app/Info.plist DERIVED_FILE_DIR=$S/d /bin/sh $SCRIPT 2>&1)
if printf '%s' "$out" | grep -q "ca-app-pub"; then expect "never prints an id" no yes; else expect "never prints an id" no no; fi
echo "$fails failed"
exit $fails
