#!/bin/sh
# Renders frame strips to shots/*.png with headless Chromium straight from file:// (no server needed).
#   sh render.sh            all strips
#   sh render.sh intro      only names starting with "intro"
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
CH="${CHROMIUM:-/Users/computer/Library/Caches/ms-playwright/chromium-1140/chrome-mac/Chromium.app/Contents/MacOS/Chromium}"
ONLY="${1:-}"

strip() { # name src extraQuery times
  case "$1" in "$ONLY"*) ;; *) return ;; esac
  n=$(echo "$4" | tr ',' '\n' | wc -l | tr -d ' ')
  w=$((n * 405 + 12)); h=$((852 + 46 + 90))   # headless window chrome eats ~90 px of the window height
  q=$(printf '%s' "$3" | sed 's/&/%26/g; s/=/%3D/g')
  "$CH" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 --allow-file-access-from-files \
    --virtual-time-budget=4000 --window-size="$w,$h" --screenshot="$HERE/shots/$1.png" \
    "file://$HERE/strip.html?src=$2&q=$q&times=$4" >/dev/null 2>&1
  echo "shots/$1.png"
}

INTRO="0,0.6,1.2,1.8,2.4,3.0,3.4"
strip intro-light        intro.html    "theme=light"        "$INTRO"
strip intro-dark         intro.html    "theme=dark"         "$INTRO"
strip intro-rm-light     intro.html    "theme=light&rm=1"   "0,0.3,0.6,1.8"
strip intro-rm-dark      intro.html    "theme=dark&rm=1"    "0,0.3,0.6,1.8"

for lv in small medium large badge; do
  case $lv in small) T="0,0.15,0.35,0.6,0.9";; medium) T="0,0.2,0.5,1.0,1.6";; large) T="0,0.25,0.6,1.2,2.0,2.8";; badge) T="0,0.25,0.6,1.2,2.0,2.6";; esac
  strip "confetti-$lv-light" confetti.html "level=$lv&theme=light" "$T"
  strip "confetti-$lv-dark"  confetti.html "level=$lv&theme=dark"  "$T"
done
strip confetti-large-calm-light confetti.html "level=large&calm=1&theme=light" "0,0.6,1.2,2.0,2.8"
strip confetti-large-rm-light   confetti.html "level=large&rm=1&theme=light"   "0,0.3,0.8,1.4"
