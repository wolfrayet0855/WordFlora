#!/bin/zsh
# Kill the simulator's mediaanalysisd every 10 s until the log file shows a line starting "EXIT".
# Usage: tools/dev/kill-mediaanalysis.sh <log> <simulator udid>
L=${1:?log file}; U=${2:?simulator udid}
until grep -q "^EXIT" "$L"; do
  for p in $(pgrep -f "simruntime/.*MediaAnalysis.framework/mediaanalysisd"); do
    pp=$(ps -o ppid= -p $p); ps -o command= -p $pp | grep -q $U && kill $p
  done
  sleep 10
done
