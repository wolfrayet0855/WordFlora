#!/bin/sh
# Renders guide pages to shots/*.png with headless Chromium straight from file:// (no server).
#   sh render.sh          all shots
#   sh render.sh p3       only names starting with "p3"
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
CH="${CHROMIUM:-/Users/computer/Library/Caches/ms-playwright/chromium-1140/chrome-mac/Chromium.app/Contents/MacOS/Chromium}"
ONLY="${1:-}"
mkdir -p "$HERE/shots"

one() { # name query
  case "$1" in "$ONLY"*) ;; *) return ;; esac
  "$CH" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=2 --allow-file-access-from-files \
    --virtual-time-budget=3000 --window-size="500,1026" --screenshot="$HERE/shots/$1.png" \
    "file://$HERE/index.html?shot=1&$2" >/dev/null 2>&1
  sips -c 1704 1000 "$HERE/shots/$1.png" >/dev/null   # keep the 393 x 852 pt phone (2x)
  echo "shots/$1.png"
}
strip() { # name extraQuery pages
  case "$1" in "$ONLY"*) ;; *) return ;; esac
  n=$(echo "$3" | tr ',' '\n' | wc -l | tr -d ' ')
  w=$((n * 405 + 12)); h=$((852 + 46 + 90))
  q=$(printf '%s' "$2" | sed 's/&/%26/g; s/=/%3D/g')
  "$CH" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 --allow-file-access-from-files \
    --virtual-time-budget=4000 --window-size="$w,$h" --screenshot="$HERE/shots/$1.png" \
    "file://$HERE/strip.html?q=$q&pages=$3" >/dev/null 2>&1
  echo "shots/$1.png"
}

for p in 1 2 3 4 5 6 7 8; do one "p$p-light" "page=$p&theme=light"; done
for p in 1 4 5 8; do one "p$p-dark" "page=$p&theme=dark"; done
one p1-ax-light "page=1&theme=light&ax=1"
one p4-ax-dark  "page=4&theme=dark&ax=1"
one p7-ax-light "page=7&theme=light&ax=1"
one p3-rm-light "page=3&theme=light&rm=1"
one p4-quiet-light "page=4&theme=light&quiet=1"
one p8-replay-dark "page=8&theme=dark&replay=1"
strip all-light "theme=light"          "1,2,3,4,5,6,7,8"
strip all-dark  "theme=dark"           "1,2,3,4,5,6,7,8"
strip all-rm-light "theme=light&rm=1"  "1,2,3,4,5,6,7,8"
