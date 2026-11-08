#!/bin/zsh
# One xcodebuild at a time under the shared lock. Usage: g3-xb.sh <action> [extra args]; log in g3-xcb.log
SP=/private/tmp/claude-501/-Users-computer-Desktop-workspace-WordFlora/4a7b4bed-9e4b-4277-b17d-f2a3956c6a07/scratchpad
REPO=/Users/computer/Desktop/workspace/WordFlora/.claude/worktrees/agent-a7c7b6a837f5b8b64
U=45D7D644-7CB7-4140-A2E1-1BAEE41E07C8
LOCK=/private/tmp/claude-501/wf-build.lock
until mkdir "$LOCK" 2>/dev/null; do sleep 20; done
# The watchdog's own sleep is killed too, so no 45 minute sleep is left behind.
trap 'rmdir "$LOCK" 2>/dev/null; pkill -P $WD 2>/dev/null; kill $WD 2>/dev/null' EXIT INT TERM
( sleep 2700; pkill -f dd-g3 ) & WD=$!
cd "$REPO" || exit 1
ACTION=$1; shift
xcodebuild "$ACTION" -project WordFlora.xcodeproj -scheme WordFlora \
  -destination "platform=iOS Simulator,id=$U" \
  -derivedDataPath "$SP/dd-g3" -jobs 4 -parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1 \
  -test-timeouts-enabled YES -default-test-execution-time-allowance 120 \
  "$@" > "$SP/g3-xcb.log" 2>&1
RC=$?
grep -E "error:|Test Case .*failed|Executed|TEST (SUCCEEDED|FAILED)|BUILD (SUCCEEDED|FAILED)|\*\* " "$SP/g3-xcb.log" | tail -60
echo "passed: $(grep -cE "Test Case .*passed" "$SP/g3-xcb.log")  rc=$RC"
exit $RC
