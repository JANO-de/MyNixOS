# vthumbs.sh  -> makes missing video thumbnails in ~/.cache/halo/gthumbs/<md5 of path>.jpg (needs ffmpeg)
command -v ffmpeg >/dev/null || exit 0
d="$HOME/.cache/halo/gthumbs"; mkdir -p "$d"
for r in "$HOME/Pictures" "$HOME/Videos"; do
  [ -d "$r" ] || continue
  find -L "$r" -maxdepth 5 -type f -not -path '*/.*' \( -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.webm' -o -iname '*.mov' -o -iname '*.avi' -o -iname '*.m4v' \) 2>/dev/null | while IFS= read -r f; do
    o="$d/$(printf '%s' "$f" | md5sum | cut -d' ' -f1).jpg"
    [ -s "$o" ] && continue
    ffmpeg -loglevel error -y -ss 1 -i "$f" -frames:v 1 -vf scale=480:-2 "$o" </dev/null 2>/dev/null || ffmpeg -loglevel error -y -i "$f" -frames:v 1 -vf scale=480:-2 "$o" </dev/null 2>/dev/null
  done
done
