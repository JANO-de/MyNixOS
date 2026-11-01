# copyimg.sh FILE -> image to the Wayland clipboard
wl-copy --type "$(file -b --mime-type -- "$1")" < "$1"
