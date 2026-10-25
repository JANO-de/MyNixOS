t="$HOME/.local/share/Trash"
rm -rf -- "$t"/files/* "$t"/files/.[!.]* "$t"/info/* 2>/dev/null
exit 0
