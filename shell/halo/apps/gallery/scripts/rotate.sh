# rotate.sh DEG FILE... -> rotates pixels in place (EXIF orientation applied first)
d=$1; shift
if command -v magick >/dev/null; then M="magick mogrify"; elif command -v mogrify >/dev/null; then M=mogrify; else exit 1; fi
for f in "$@"; do $M -auto-orient -rotate "$d" -- "$f"; done
