#!/bin/sh
# Renders mockup states to shots/*.png with headless Chromium from file:// (no server needed).
#   sh render.sh          all     sh render.sh a-     only names starting with "a-"
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
CH="${CHROMIUM:-/Users/computer/Library/Caches/ms-playwright/chromium-1140/chrome-mac/Chromium.app/Contents/MacOS/Chromium}"
ONLY="${1:-}"; mkdir -p "$HERE/shots"
shot() { # name query [height]
  case "$1" in "$ONLY"*) ;; *) return ;; esac
  h="${3:-852}"
  "$CH" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=2 --allow-file-access-from-files \
    --virtual-time-budget=3000 --window-size="393,$((h + 87))" --screenshot="$HERE/shots/$1.png" \
    "file://$HERE/card.html?$2&static=1" >/dev/null 2>&1

  magick "$HERE/shots/$1.png" -crop 786x$((h*2))+0+0 +repage "$HERE/shots/$1.png"
  echo "shots/$1.png"
}
for v in ${VARIANTS:-a b c}; do
  for t in light dark; do
    shot "$v-rest-ad-$t"   "v=$v&card=rest&plan=ad&theme=$t"
    shot "$v-rest-plus-$t" "v=$v&card=rest&plan=plus&theme=$t"
    shot "$v-break-$t"     "v=$v&card=break&plan=kid&theme=$t"
  done
  shot "$v-rest-free-light"  "v=$v&card=rest&plan=free&theme=light"
  shot "$v-rest-large-light" "v=$v&card=rest&plan=ad&theme=light&scale=1.65&tall=1" 1240
  shot "$v-break-large-dark" "v=$v&card=break&plan=kid&theme=dark&scale=1.65&tall=1" 1240
done
