#!/usr/bin/env bash
# halos1 battery baseline (F1). Run ON BATTERY, screen on, hands off.
# Usage: halos1-baseline.sh [seconds=600] [tag=idle]
set -u
DUR=${1:-600}; TAG=${2:-idle}
OUT=$HOME/halos1-baseline-$(date +%Y%m%d-%H%M%S)-$TAG.txt
BAT=$(ls -d /sys/class/power_supply/BAT* | head -n1)
AC=$(cat /sys/class/power_supply/A*/online 2>/dev/null | head -n1)
[ "${AC:-0}" = 1 ] && echo "WARNING: AC connected, drain invalid" >&2
T=$(mktemp -d)

energy() { # uWh
  if [ -r "$BAT/energy_now" ]; then cat "$BAT/energy_now"
  else echo $(( $(cat "$BAT/charge_now") * $(cat "$BAT/voltage_now") / 1000000 )); fi
}
snap() { # pid name ctxswitches cputicks
  for d in /proc/[0-9]*; do
    awk -v p="${d#/proc/}" '
      FILENAME ~ /status$/ { if ($1=="Name:") n=$2; if ($1 ~ /ctxt_switches:$/) c+=$2; next }
      { sub(/^.*\) /,""); t=$12+$13 }
      END { print p, n, c, t }' "$d/status" "$d/stat" 2>/dev/null
  done
}

E0=$(energy); snap > "$T/b0"; sleep "$DUR"; E1=$(energy); snap > "$T/b1"

{
  echo "tag=$TAG dur=${DUR}s start=$(date -d "-${DUR} sec" +%T) kernel=$(uname -r)"
  echo "droidloomd=$(systemctl is-active droidloomd) ac=${AC:-?} batt=$(cat $BAT/status) cap=$(cat $BAT/capacity)%"
  echo "backlight=$(cat /sys/class/backlight/*/brightness 2>/dev/null | head -n1)/$(cat /sys/class/backlight/*/max_brightness 2>/dev/null | head -n1)"
  awk -v a="$E0" -v b="$E1" -v d="$DUR" 'BEGIN{printf "drain=%d uWh avg=%.2f W (battery resolution is coarse; use >=600 s)\n",a-b,(a-b)*3600/(d*1e6)}'
  awk -v d="$DUR" 'NR==FNR{c[$1]=$3;t[$1]=$4;next} ($1 in c){x=($3-c[$1])/d; y=($4-t[$1])/d; printf "%s %s %.1f %.2f\n",$1,$2,x,y; X+=x; Y+=y} END{printf "TOTAL - %.1f %.2f\n",X,Y}' "$T/b0" "$T/b1" > "$T/m"
  echo "-- total ctx/s and cpu% --"; grep '^TOTAL' "$T/m"
  echo "-- top ctx switches/s (wakeup proxy): pid name ctx/s cpu% --"; grep -v '^TOTAL' "$T/m" | sort -k3 -nr | head -n 12
  echo "-- top cpu% --"; grep -v '^TOTAL' "$T/m" | sort -k4 -nr | head -n 8
  echo "-- ram --"; free -m; ps -eo rss,comm --sort=-rss | head -n 10
} | tee "$OUT"
echo "saved: $OUT"
rm -rf "$T"
