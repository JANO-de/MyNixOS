# stat.sh PATH [deep] -> 1 type|perm|owner|mtime|size  2 mime  3 item count  4 deep size  5.. text preview
f=$1
stat -c '%F|%A|%U:%G|%y|%s' -- "$f" 2>/dev/null || exit 1
m=$(file -b --mime-type -- "$f" 2>/dev/null); echo "${m:-unknown}"
if [ -d "$f" ]; then ls -A -- "$f" 2>/dev/null | wc -l; if [ "$2" = deep ]; then du -sb -- "$f" 2>/dev/null | cut -f1; else echo 0; fi; else echo 0; echo 0; fi
case "$m" in text/*|application/json|application/xml|application/toml|application/x-shellscript) head -c 800 -- "$f" ;; esac
