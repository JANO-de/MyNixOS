# info.sh FILE -> key=value lines (size, mtime, dim, camera, exposure ...)
f=$1
stat -c 'size=%s' -- "$f"; stat -c 'mtime=%Y' -- "$f"
case "${f,,}" in
  *.mp4|*.mkv|*.webm|*.mov|*.avi|*.m4v)
    command -v ffprobe >/dev/null && ffprobe -v error -select_streams v:0 -show_entries stream=width,height:format=duration -of default=nw=1 "$f" 2>/dev/null | awk -F= '/^width/{w=$2}/^height/{h=$2}/^duration/{printf "dur=%d\n",$2}END{if(w)print "dim=" w "x" h}' ;;
  *)
    if command -v magick >/dev/null; then I="magick identify"; elif command -v identify >/dev/null; then I=identify; fi
    [ -n "$I" ] && $I -format 'dim=%wx%h\nmake=%[EXIF:Make]\nmodel=%[EXIF:Model]\nf=%[EXIF:FNumber]\nexp=%[EXIF:ExposureTime]\niso=%[EXIF:ISOSpeedRatings]\nfl=%[EXIF:FocalLength]\ndt=%[EXIF:DateTimeOriginal]\n' "${f}[0]" 2>/dev/null ;;
esac
exit 0
