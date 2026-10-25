# trash.sh PATH...  -> freedesktop trash; prints "orig<TAB>trashname"
t="$HOME/.local/share/Trash"; mkdir -p "$t/files" "$t/info"
for f in "$@"; do
  b=$(basename -- "$f"); n=$b; i=1
  while [ -e "$t/files/$n" ] || [ -e "$t/info/$n.trashinfo" ]; do n="$b.$i"; i=$((i+1)); done
  p=$(realpath -s -- "$f" | sed 's/%/%25/g; s/ /%20/g')
  printf '[Trash Info]\nPath=%s\nDeletionDate=%s\n' "$p" "$(date +%Y-%m-%dT%H:%M:%S)" > "$t/info/$n.trashinfo"
  mv -- "$f" "$t/files/$n" && printf '%s\t%s\n' "$f" "$n"
done
