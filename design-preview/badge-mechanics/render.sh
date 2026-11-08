#!/bin/sh
# Renders the badge-mechanics preview to shots/*.png with headless Chromium from file:// (no server needed).
#   sh render.sh          all     sh render.sh net    only names starting with "net"
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
CH="${CHROMIUM:-/Users/computer/Library/Caches/ms-playwright/chromium-1140/chrome-mac/Chromium.app/Contents/MacOS/Chromium}"
ONLY="${1:-}"; mkdir -p "$HERE/shots"
shot() { # name query width height
  case "$1" in "$ONLY"*) ;; *) return ;; esac
  "$CH" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=2 --allow-file-access-from-files \
    --virtual-time-budget=2000 --window-size="$3,$4" --screenshot="$HERE/shots/$1.png" \
    "file://$HERE/index.html?$2&static=1" >/dev/null 2>&1
  echo "shots/$1.png"
}
shot assets-light "theme=light&section=assets" 820 760
shot assets-dark  "theme=dark&section=assets"  820 760
shot notes-light  "theme=light&section=notes"  1000 700
shot notes-dark   "theme=dark&section=notes"   1000 700
shot net-light    "theme=light&section=net"    1000 560
shot net-dark     "theme=dark&section=net"     1000 560
shot prune-light  "theme=light&section=prune"  1000 640
shot prune-dark   "theme=dark&section=prune"   1000 640
shot mist-light   "theme=light&section=mist"   1000 700
shot mist-dark    "theme=dark&section=mist"    1000 700
