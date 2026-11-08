#!/bin/zsh
# Between test batches only: fresh simulator with mediaanalysisd disabled inside it.
# Usage: tools/dev/sim-reset.sh <udid>
UDID=${1:?simulator udid}
xcrun simctl shutdown "$UDID" 2>/dev/null
xcrun simctl erase "$UDID"
xcrun simctl boot "$UDID"
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1
xcrun simctl spawn "$UDID" launchctl disable user/foreground/com.apple.mediaanalysisd
xcrun simctl spawn "$UDID" launchctl print-disabled user/foreground | grep mediaanalysisd
