# cpmv.sh MODE(cp|mv) DESTDIR SRC...  -> prints "src<TAB>dest" per item; never overwrites ("name (1).ext")
m=$1; d=$2; shift 2
for f in "$@"; do
  b=$(basename -- "$f"); n=$b; i=1
  [ "$m" = mv ] && [ "$(dirname -- "$f")" = "$d" ] && continue
  while [ -e "$d/$n" ]; do
    if [[ "$b" == *.* && "$b" != .* ]]; then n="${b%.*} ($i).${b##*.}"; else n="$b ($i)"; fi
    i=$((i+1))
  done
  if [ "$m" = cp ]; then cp -r -- "$f" "$d/$n"; else mv -- "$f" "$d/$n"; fi && printf '%s\t%s\n' "$f" "$d/$n"
done
