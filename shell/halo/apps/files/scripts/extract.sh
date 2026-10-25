# extract.sh ARCHIVE -> extracts into a new sibling folder, prints it
f=$1; d=$(dirname -- "$f"); b=$(basename -- "$f")
s="${b%.tar.*}"; [ "$s" = "$b" ] && s="${b%.*}"
n=$s; i=1; while [ -e "$d/$n" ]; do n="$s ($i)"; i=$((i+1)); done
mkdir -p -- "$d/$n"
case "${b,,}" in
  *.zip) unzip -q -- "$f" -d "$d/$n" ;;
  *.7z) 7z x -bso0 -bsp0 -o"$d/$n" -- "$f" ;;
  *) tar xf "$f" -C "$d/$n" ;;
esac && printf '%s\n' "$d/$n"
