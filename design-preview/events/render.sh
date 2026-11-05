#!/bin/sh
# Renders every mockup state to shots/*.png (393 wide, 852 tall @2x unless a height is given) with headless Chromium from file://.
#   sh render.sh          all     sh render.sh frost    only names starting with "frost"
# Chromium can be flaky in long batches: re-run with a name prefix if a file is missing.
HERE="$(cd "$(dirname "$0")" && pwd)"
CH="${CHROMIUM:-/Users/computer/Library/Caches/ms-playwright/chromium-1140/chrome-mac/Chromium.app/Contents/MacOS/Chromium}"
ONLY="${1:-}"; mkdir -p "$HERE/shots"
shot() { # name query [height]
  case "$1" in "$ONLY"*) ;; *) return ;; esac
  h="${3:-852}"
  "$CH" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=2 --allow-file-access-from-files \
    --virtual-time-budget=3000 --window-size="393,$((h + 87))" --screenshot="$HERE/shots/$1.png" \
    "file://$HERE/mock.html?$2&static=1" >/dev/null 2>&1 || true
  magick "$HERE/shots/$1.png" -crop 786x$((h*2))+0+0 +repage "$HERE/shots/$1.png"
  echo "shots/$1.png"
}
for t in light dark; do
  for s in warn-wind warn-wind-set warn-dry kit banner-wind chips bar shed shed-out snug dry dry-mild bugs wind frost heat hail flood shrug; do
    shot "$s-$t" "s=$s&theme=$t"
  done
  for s in wind dry bugs; do shot "$s-rm-$t" "s=$s-rm&theme=$t"; done
  shot "ax-warn-wind-$t" "s=ax-warn-wind&theme=$t" 720
  shot "ax-dry-$t" "s=ax-dry&theme=$t" 1140
  shot "ax-shed-$t" "s=ax-shed&theme=$t" 1180
done
