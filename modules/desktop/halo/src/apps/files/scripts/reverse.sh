# reverse.sh FROM TO [FROM TO ...]  (undo of a move)
while [ $# -gt 1 ]; do mkdir -p -- "$(dirname -- "$2")"; mv -n -- "$1" "$2"; shift 2; done
