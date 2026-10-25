# cpmvp.sh MODE(cp|mv) DESTDIR SRC...  -> streams: "T<TAB>total", "P<TAB>done", "D<TAB>src<TAB>dest"
m=$1; d=$2; shift 2
sz() { du -sb -- "$1" 2>/dev/null | cut -f1; }
sizes=(); total=0
for f in "$@"; do s=$(sz "$f"); s=${s:-0}; sizes+=("$s"); total=$((total+s)); done
printf 'T\t%s\n' "$total"
pid=
trap '[ -n "$pid" ] && kill $pid 2>/dev/null; exit 130' TERM INT
doneb=0; i=0
for f in "$@"; do
  b=$(basename -- "$f"); n=$b; k=1
  if [ "$m" = mv ] && [ "$(dirname -- "$f")" = "$d" ]; then i=$((i+1)); continue; fi
  while [ -e "$d/$n" ]; do
    if [[ "$b" == *.* && "$b" != .* ]]; then n="${b%.*} ($k).${b##*.}"; else n="$b ($k)"; fi
    k=$((k+1))
  done
  if [ "$m" = cp ]; then cp -r -- "$f" "$d/$n" & else mv -- "$f" "$d/$n" & fi
  pid=$!
  while kill -0 "$pid" 2>/dev/null; do
    c=$(sz "$d/$n"); printf 'P\t%s\n' "$((doneb+${c:-0}))"
    sleep 0.25
  done
  if wait "$pid"; then printf 'D\t%s\t%s\n' "$f" "$d/$n"; fi
  pid=
  doneb=$((doneb+${sizes[$i]}))
  i=$((i+1))
done
printf 'P\t%s\n' "$total"
