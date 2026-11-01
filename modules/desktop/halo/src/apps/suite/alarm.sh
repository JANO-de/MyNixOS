d="$HOME/.config/systemd/user"
id=$2
case "$1" in
set)
  when=$3; label=$4
  mkdir -p "$d"
  case "$when" in *-*-*\ *) cal="$when:00" ;; *) cal="*-*-* $when:00" ;; esac
  printf '%s' "$label" > "$d/halo-alarm-$id.label"
  cat > "$d/halo-alarm-$id.service" <<UNIT
[Unit]
Description=Halo alarm $id
[Service]
Type=oneshot
ExecStart=/bin/sh -c '/run/current-system/sw/bin/notify-send -u critical -i appointment-soon "Halo" "\$(cat %h/.config/systemd/user/halo-alarm-$id.label)"'
UNIT
  cat > "$d/halo-alarm-$id.timer" <<UNIT
[Unit]
Description=Halo alarm $id
[Timer]
OnCalendar=$cal
AccuracySec=1s
[Install]
WantedBy=timers.target
UNIT
  systemctl --user daemon-reload
  systemctl --user enable --now "halo-alarm-$id.timer"
  ;;
clear)
  systemctl --user disable --now "halo-alarm-$id.timer" 2>/dev/null
  rm -f "$d/halo-alarm-$id".service "$d/halo-alarm-$id".timer "$d/halo-alarm-$id".label
  systemctl --user daemon-reload
  ;;
esac
exit 0
