#!/bin/zsh
# G4a hold steps (AdMob hardening). Takes the build lock ONCE for the whole run under the lock rule below, boots the
# given simulator, runs the steps, shuts it down. Never prints an ad id: the Release checks print key names,
# real/TEST/EMPTY, counts and equal/not equal only.
#
# Usage: SIM=<udid> [WT=<worktree>] [OUT=<dir>] [LOCKED=1] zsh tools/dev/g4a-hold.sh [step ...]
#   steps: build unit ui shots probe release   (default: all, in that order)
#   WT   the checkout to build (default: this repo's top level)
#   OUT  derived data, logs and shots (default /private/tmp/claude-501/g4a-hold)
#   LOCKED=1  the caller already holds wf-build.lock and has booted SIM (an integration hold); skip the lock here
# The Release step symlinks the owner's ignored Config/Ads.local.xcconfig from the main checkout for its second build
# and removes the link on exit. Never commit that file.
set -u
W=${WT:-$(cd ${0:A:h}/../.. && pwd)}
OUT=${OUT:-/private/tmp/claude-501/g4a-hold}
MAIN_LOCAL=/Users/computer/Desktop/workspace/WordFlora/Config/Ads.local.xcconfig
LOCK=/private/tmp/claude-501/wf-build.lock
UDID=${SIM:?set SIM to the simulator UDID}
DD=$OUT/dd; DDR=$OUT/dd-rel; LOGS=$OUT/logs; SHOTS=$OUT/shots
mkdir -p $LOGS $SHOTS
steps=(${@:-build unit ui shots probe release})
FLAGS=(-jobs 4 -parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1 -test-timeouts-enabled YES -default-test-execution-time-allowance 120)

# Lock rule (lead, all builders): take the lock and boot the sim only when (a) the lock is free, (b) no
# `xcodebuild ... test` of ANY project is running on the Mac, and (c) the 1-minute load is under 15 for two readings.
load1() { sysctl -n vm.loadavg | awk '{print int($2)}'; }
otherTests() { pgrep -fl "xcodebuild" | grep -E " (test|test-without-building|build-for-testing)( |$)" | grep -v -- "$DD" ; }
clearToGo() {
  [ ! -d $LOCK ] || return 1
  [ -z "$(otherTests)" ] || { echo "an xcodebuild test is running elsewhere; waiting"; return 1; }
  [ $(load1) -lt 15 ] || { echo "load $(load1); waiting"; return 1; }
  sleep 150                                               # second reading, 2.5 min later
  [ $(load1) -lt 15 ] && [ -z "$(otherTests)" ] && [ ! -d $LOCK ]
}
WD=0; OWNLOCK=0
cleanup() {
  rm -f $W/Config/Ads.local.xcconfig 2>/dev/null          # only ever our symlink (the file is ignored)
  [ $WD -gt 0 ] && { pkill -P $WD 2>/dev/null; kill $WD 2>/dev/null; }
  if [ $OWNLOCK = 1 ]; then xcrun simctl shutdown $UDID 2>/dev/null; rmdir $LOCK 2>/dev/null; fi
}
trap cleanup EXIT INT TERM
if [ "${LOCKED:-0}" != 1 ]; then
  until clearToGo && mkdir $LOCK 2>/dev/null; do sleep 30; done
  OWNLOCK=1; echo "lock taken $(date)"; uptime
fi

boot() {
  xcrun simctl bootstatus $UDID -b >/dev/null 2>&1 || xcrun simctl boot $UDID
  xcrun simctl bootstatus $UDID -b >/dev/null
  xcrun simctl spawn $UDID launchctl disable user/foreground/com.apple.mediaanalysisd 2>/dev/null
  xcrun simctl spawn $UDID launchctl remove com.apple.mediaanalysisd 2>/dev/null
}
summary() { grep -E "error:|Test Case .*failed|Executed|TEST (SUCCEEDED|FAILED)|BUILD (SUCCEEDED|FAILED)|TEST BUILD|Check ad ids|collapsible probe" $1 | tail -40; }
xb() { # name, xcodebuild args...
  local name=$1; shift
  ( cd $W && exec xcodebuild "$@" -project WordFlora.xcodeproj -scheme WordFlora "${FLAGS[@]}" ) > $LOGS/$name.log 2>&1 &
  local XB=$!
  # The watchdog starts only once xcodebuild runs (lead rule): 45 min for this one build; its sleep dies with it.
  ( sleep 2700; kill $XB 2>/dev/null ) & WD=$!
  wait $XB; local rc=$?
  pkill -P $WD 2>/dev/null; kill $WD 2>/dev/null; WD=0
  echo "== $name rc=$rc"; summary $LOGS/$name.log; return $rc
}
DEST=(-destination "platform=iOS Simulator,id=$UDID" -derivedDataPath $DD)

for st in $steps; do case $st in
  build)
    [ $OWNLOCK = 1 ] && boot
    xb build-for-testing build-for-testing "${DEST[@]}" ;;
  unit)
    xb unit test-without-building "${DEST[@]}" -only-testing:WordFloraTests ;;
  ui)
    for c in AdFormatsUITests RestCardUITests HomeLayoutUITests; do
      xb ui-$c test-without-building "${DEST[@]}" -only-testing:WordFloraUITests/$c
    done ;;
  shots)
    export TEST_RUNNER_SCREENSHOT_DIR=$SHOTS
    xb shots test-without-building "${DEST[@]}" -only-testing:WordFloraUITests/FadedBloomShotUITests
    unset TEST_RUNNER_SCREENSHOT_DIR
    ls -la $SHOTS ;;
  probe)
    export TEST_RUNNER_WF_LIVE_ADS=1
    xb probe test-without-building "${DEST[@]}" -only-testing:WordFloraTests/CollapsibleTestIdProbeTests
    unset TEST_RUNNER_WF_LIVE_ADS ;;
  release)
    zsh $W/tools/ads/check-ad-ids-test.sh | tail -1
    [ -L $W/Config/Ads.local.xcconfig ] && rm -f $W/Config/Ads.local.xcconfig
    [ -e $W/Config/Ads.local.xcconfig ] && { echo "a real local file is in this checkout: run the no-local build elsewhere"; exit 1; }
    xb release-nolocal build -configuration Release CODE_SIGNING_ALLOWED=NO -destination "generic/platform=iOS Simulator" -derivedDataPath $DDR
    echo "(expect BUILD FAILED above with 'Check ad ids' errors: no local file means Google's test ids)"
    ln -s $MAIN_LOCAL $W/Config/Ads.local.xcconfig
    xb release-local build -configuration Release CODE_SIGNING_ALLOWED=NO -destination "generic/platform=iOS Simulator" -derivedDataPath $DDR
    echo "(expect BUILD SUCCEEDED with 'Check ad ids: Release ids present...')"
    APP=$DDR/Build/Products/Release-iphonesimulator/WordFlora.app
    if [ -d $APP ]; then
      P=$APP/Info.plist
      for k in AdMobBannerUnitID AdMobBannerGardenUnitID AdMobBannerGardenCollapsibleUnitID AdMobInterstitialUnitID AdMobRewardedUnitID AdMobRewardedHintUnitID AdMobRewardedWakeUnitID AdMobAppOpenUnitID AdMobNativeUnitID GADApplicationIdentifier; do
        v=$(/usr/libexec/PlistBuddy -c "Print :$k" $P 2>/dev/null)
        case "$v" in *3940256099942544*) t=TEST;; "") t=EMPTY;; *) t=real;; esac
        echo "$k: $t"
      done
      g=$(/usr/libexec/PlistBuddy -c "Print :AdMobBannerGardenUnitID" $P); h=$(/usr/libexec/PlistBuddy -c "Print :AdMobBannerUnitID" $P)
      [ "$g" = "$h" ] && echo "Garden == Home: yes" || echo "Garden == Home: NO"
      # Expect 0 for each: the Debug-only strings are compiled out, and no full Google test id ships.
      for needle in uitest-ads-fake uitest-toast-hold uitest-adcaps-fast "-adcaps" FakeAdHost "TEST AD" uitest-store-slow uitest-store-fail debugProbeCollapsible "ca-app-pub-3940256099942544"; do
        echo "binary strings '$needle': $(strings -a $APP/WordFlora | grep -c -- "$needle")"
      done
      echo "applovin in bundle: $(grep -ril applovin $APP | wc -l | tr -d ' ')"
    fi
    rm -f $W/Config/Ads.local.xcconfig ;;
esac; done
echo "hold done $(date)"
