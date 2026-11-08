#!/bin/zsh
# One xcodebuild at a time under the shared lock, with a watchdog.
# Usage: SIM=<udid> [WT=<worktree>] [DD=<derived data dir>] tools/dev/xb.sh <action> [extra xcodebuild args]
# Log goes to $LOG (default $DD/../xcb.log). Wait time is unlimited; the build itself is killed after 45 minutes.
LOCK=${LOCK:-/private/tmp/claude-501/wf-build.lock}
WT=${WT:-$(git rev-parse --show-toplevel)}
DD=${DD:-/private/tmp/claude-501/dd-$(basename "$WT")}
LOG=${LOG:-$DD.xcb.log}
: ${SIM:?set SIM to a simulator UDID (xcrun simctl list devices)}
mkdir -p "$(dirname "$LOCK")"
until mkdir "$LOCK" 2>/dev/null; do sleep 20; done
# The watchdog's own sleep is killed too, so no 45 minute sleep is left behind.
trap 'rmdir "$LOCK" 2>/dev/null; pkill -P $WD 2>/dev/null; kill $WD 2>/dev/null' EXIT INT TERM
( sleep 2700; pkill -f "$DD" ) & WD=$!
cd "$WT" || exit 1
ACTION=$1; shift
xcodebuild "$ACTION" -project WordFlora.xcodeproj -scheme WordFlora \
  -destination "platform=iOS Simulator,id=$SIM" \
  -derivedDataPath "$DD" -jobs 4 -parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1 \
  -test-timeouts-enabled YES -default-test-execution-time-allowance 120 \
  "$@" > "$LOG" 2>&1
RC=$?
grep -E "error:|Test Case .*failed|Executed|TEST (SUCCEEDED|FAILED)|BUILD (SUCCEEDED|FAILED)|\*\* " "$LOG" | tail -60
echo "passed: $(grep -cE "Test Case .*passed" "$LOG")  rc=$RC"
exit $RC
