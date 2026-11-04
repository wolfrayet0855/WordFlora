#!/bin/zsh
C="/Users/computer/Library/Caches/ms-playwright/chromium-1140/chrome-mac/Chromium.app/Contents/MacOS/Chromium"
O=/Users/computer/Desktop/workspace/WordFlora/design-preview/logo/a
U="http://localhost:8765/logo/a/render.html"
shot(){ # out w h query
  "$C" --headless=old --disable-gpu --hide-scrollbars --force-device-scale-factor=1 --virtual-time-budget=3000 --window-size=$2,$3 --screenshot=$O/$1 "$U?$4" >/dev/null 2>&1
}
for s in 1024 180 60 29; do
  shot icon-$s.png $s $s "v=icon&size=$s"
  shot icon-dark-$s.png $s $s "v=icon-dark&size=$s"
  shot icon-tinted-$s.png $s $s "v=icon-tinted&size=$s"
done
# wordmark: aspect from viewBox
A=$(grep -o 'viewBox="[^"]*"' $O/wordmark.svg | head -1 | awk -F'[" ]' '{print $4/$5}')
for w in 320 120 191; do
  h=$(python3 -c "import math;print(math.ceil($w/$A))")
  shot wordmark-$w.png $w $h "v=wordmark&size=$w&bg=FAF7F0"
  shot wordmark-dark-$w.png $w $h "v=wordmark-dark&size=$w&bg=1A2E1A"
  shot wordmark-mono-$w.png $w $h "v=wordmark-mono&size=$w&bg=FFFFFF"
done
ls $O/*.png | wc -l
