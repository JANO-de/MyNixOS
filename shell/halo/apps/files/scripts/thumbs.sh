# thumbs.sh FILE...  -> video/pdf thumbnails in ~/.cache/halo/gthumbs/<md5 of path>.jpg (shared with Gallery)
d="$HOME/.cache/halo/gthumbs"; mkdir -p "$d"
for f in "$@"; do
  o="$d/$(printf '%s' "$f" | md5sum | cut -d' ' -f1).jpg"
  [ -s "$o" ] && continue
  case "${f,,}" in
    *.pdf) command -v pdftoppm >/dev/null && pdftoppm -jpeg -f 1 -l 1 -scale-to 480 -singlefile -- "$f" "${o%.jpg}" 2>/dev/null ;;
    *.mp4|*.mkv|*.webm|*.mov|*.avi|*.m4v)
      command -v ffmpeg >/dev/null && { ffmpeg -loglevel error -y -ss 1 -i "$f" -frames:v 1 -vf scale=480:-2 "$o" </dev/null 2>/dev/null || ffmpeg -loglevel error -y -i "$f" -frames:v 1 -vf scale=480:-2 "$o" </dev/null 2>/dev/null; } ;;
  esac
done
exit 0
