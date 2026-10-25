# restore.sh TRASHNAME...  -> move back to the original path from the .trashinfo
t="$HOME/.local/share/Trash"
for n in "$@"; do
  i="$t/info/$n.trashinfo"; [ -e "$i" ] || continue
  o=$(sed -n 's/^Path=//p' "$i" | head -1); o=$(printf '%b' "${o//%/\\x}")
  mkdir -p -- "$(dirname -- "$o")"; d="$o"; k=1
  while [ -e "$d" ]; do d="$o ($k)"; k=$((k+1)); done
  mv -- "$t/files/$n" "$d" && rm -f -- "$i"
done
