# compress.sh DIR OUT FMT(zip|tgz|txz|7z) NAME...   (NAMEs relative to DIR) -> prints the archive path
cd "$1" || exit 1; out=$2; fmt=$3; shift 3
case $fmt in
  zip) zip -rq -- "$out" "$@" ;;
  tgz) tar czf "$out" -- "$@" ;;
  txz) tar cJf "$out" -- "$@" ;;
  7z) 7z a -bso0 -bsp0 -- "$out" "$@" ;;
esac && printf '%s\n' "$PWD/$out"
