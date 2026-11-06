#!/bin/sh
# Renders the Quiet Garden offer to shots/*.png with headless Chromium from file:// (no server needed).
#   sh render.sh          all     sh render.sh dark   only names starting with "dark"
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
CH="${CHROMIUM:-/Users/computer/Library/Caches/ms-playwright/chromium-1140/chrome-mac/Chromium.app/Contents/MacOS/Chromium}"
ONLY="${1:-}"; mkdir -p "$HERE/shots"
shot() { # name query [height]
  case "$1" in "$ONLY"*) ;; *) return ;; esac
  h="${3:-852}"
  "$CH" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=2 --allow-file-access-from-files \
    --virtual-time-budget=3000 --window-size="393,$((h + 87))" --screenshot="$HERE/shots/$1.png" \
    "file://$HERE/screen.html?$2&static=1" >/dev/null 2>&1
  magick "$HERE/shots/$1.png" -crop 786x$((h*2))+0+0 +repage "$HERE/shots/$1.png"
  echo "shots/$1.png"
}
shot light        "theme=light"
shot dark         "theme=dark"
shot large-light  "theme=light&scale=1.65&tall=1" 1240
shot large-dark   "theme=dark&scale=2.1&tall=1" 1560
