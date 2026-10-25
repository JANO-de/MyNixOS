# scan.sh ROOT...  -> "mtime<TAB>size<TAB>path" for every photo / video (hidden dirs skipped)
for r in "$@"; do
  [ -d "$r" ] || continue
  (cd "$r" && find -L . -maxdepth 5 -type f -not -path '*/.*' \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.bmp' -o -iname '*.avif' -o -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.webm' -o -iname '*.mov' -o -iname '*.avi' -o -iname '*.m4v' \) -printf '%T@\t%s\t%P\n' 2>/dev/null | awk -v r="$r" -F'\t' '{print $1"\t"$2"\t"r"/"$3}')

done
