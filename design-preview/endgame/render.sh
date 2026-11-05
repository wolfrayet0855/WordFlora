#!/bin/sh
# Renders every endgame / garden weather screen to shots/*.png with headless Chromium from file:// (no server needed),
# then checks the visible text, aria-label and alt of each screen against CopySafety.banned plus the spec avoid list.
#   sh render.sh          all     sh render.sh puzzle     only names starting with "puzzle"
# Revision 0 shots are kept in shots/v1/ (from screens-v1.html).
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
CH="${CHROMIUM:-/Users/computer/Library/Caches/ms-playwright/chromium-1140/chrome-mac/Chromium.app/Contents/MacOS/Chromium}"
ONLY="${1:-}"; mkdir -p "$HERE/shots"
BASE='miss|lonely|alone|waiting|abandon|neglect|forgot|forget|die|dies|died|dying|dead|lost|empty|left|broken|hurry|now or never|expires|only|last|smart|genius|talented|best gardener|better than|beat|plus|save|rescue|danger|destroy|warning|alert|too late|hearts?'
shot() { # name query [height]
  case "$1" in "$ONLY"*) ;; *) return ;; esac
  h="${3:-852}"
  "$CH" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=2 --allow-file-access-from-files \
    --virtual-time-budget=3000 --window-size="393,$((h + 87))" --screenshot="$HERE/shots/$1.png" \
    "file://$HERE/screens.html?$2&static=1" >/dev/null 2>&1
  magick "$HERE/shots/$1.png" -crop 786x$((h*2))+0+0 +repage "$HERE/shots/$1.png"
  # "storm" is banned in kid-facing screens; the 13+ Wild Weather text in Settings uses the lead's wording.
  case "$1" in settings*) B="\\b($BASE)\\b" ;; *) B="\\b($BASE|storms?)\\b" ;; esac
  "$CH" --headless=new --disable-gpu --allow-file-access-from-files --virtual-time-budget=2000 --dump-dom \
    "file://$HERE/screens.html?$2&static=1" 2>/dev/null | sed -n '/<div id="root">/,/<script>/p' \
    | sed -E 's/<(svg|path|ellipse|circle|rect|g)[^>]*>//g; s/ (style|src|class|d|viewBox|transform)="[^"]*"//g' | grep -oiE "$B" | sort -u | sed "s/^/  COPY WARNING in $1: /" || true
  echo "shots/$1.png"
}
for t in light dark; do
  for s in a gold home share next intro puzzle part2 cap mended settings; do shot "$s-$t" "s=$s&theme=$t"; done
done
shot "share-kid-light" "s=share&kid=1&theme=light"
shot "a-rm-dark"       "s=a&theme=dark&rm=1"
shot "mended-rm-light" "s=mended&theme=light&rm=1"
shot "puzzle-large-light" "s=puzzle&theme=light&scale=1.3&tall=1" 1060
shot "next-large-dark"    "s=next&theme=dark&scale=1.3&tall=1" 1120
