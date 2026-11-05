#!/bin/sh
# Renders every Garden Path state to shots/*.png with headless Chromium straight from file:// (no server).
#   sh render.sh          all shots
#   sh render.sh mid      only names starting with "mid"
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
CH="${CHROMIUM:-/Users/computer/Library/Caches/ms-playwright/chromium-1140/chrome-mac/Chromium.app/Contents/MacOS/Chromium}"
ONLY="${1:-}"
shot() { # name query height
  case "$1" in "$ONLY"*) ;; *) return ;; esac
  "$CH" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 --allow-file-access-from-files \
    --virtual-time-budget=3000 --window-size="393,$3" --screenshot="$HERE/shots/$1.png" \
    "file://$HERE/index.html?frame=1&$2" >/dev/null 2>&1
  echo "shots/$1.png"
}
shot new-light   "state=new&theme=light"  2050
shot mid-light   "state=mid&theme=light"  2050
shot mid-dark    "state=mid&theme=dark"   2050
shot late-light  "state=late&theme=light" 2050
shot late-dark   "state=late&theme=dark"  2050
shot all-light   "state=all&theme=light"  2050
shot all-dark    "state=all&theme=dark"   2050
shot large-light "state=mid&theme=light&text=large" 2950
shot large-dark  "state=mid&theme=dark&text=large"  2950
