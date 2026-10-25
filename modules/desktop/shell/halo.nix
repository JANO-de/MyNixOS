{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.modules.desktop;
  shellDir = ../../../shell/halo;

  # hyprctl needs the instance signature; fall back to scanning if the session did not export it.
  launcher = pkgs.writeShellScript "halo-launch" ''
    if [ -z "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
      HYPRLAND_INSTANCE_SIGNATURE=$(${pkgs.findutils}/bin/find "$XDG_RUNTIME_DIR/hypr" -mindepth 1 -maxdepth 1 -type d ! -name chronos-shell -printf '%f\n' | ${pkgs.coreutils}/bin/head -1)
      export HYPRLAND_INSTANCE_SIGNATURE
    fi
    echo hidden > "$XDG_RUNTIME_DIR/kbd-visible"
    exec ${lib.getExe pkgs.quickshell} -p ${shellDir}
  '';

  # halo-ctl call home toggle|open|close  (talks to the running shell by its config path)
  haloCtl = pkgs.writeShellScriptBin "halo-ctl" ''
    exec ${lib.getExe pkgs.quickshell} -p ${shellDir} ipc "$@"
  '';
  # halo-app NAME: run a Halo app (apps/NAME.qml) as its own Wayland window. argv[0] = halo-NAME so the
  # app_id matches the .desktop entry. Prefers the dev copy in ~/halo (scripts/halo-dev.sh).
  haloApp = pkgs.writeShellScriptBin "halo-app" ''
    d="$HOME/halo"; [ -f "$d/apps/$1.qml" ] || d=${shellDir}
    exec -a "halo-$1" ${lib.getExe pkgs.quickshell} -n -p "$d/apps/$1.qml"
  '';
  haloAppEntry = name: title: icon: cat: pkgs.makeDesktopItem {
    name = "halo-${name}";
    desktopName = title;
    exec = "halo-app ${name}";
    icon = icon;
    categories = [ cat ];
    startupWMClass = "halo-${name}";
  };
  # halo-recolor-icons DARK MID LIGHT OUTDIR NAME...: Papirus SVGs recoloured with the wallpaper palette (Theme.qml).
  haloRecolorIcons = pkgs.writeShellScriptBin "halo-recolor-icons" ''
    export HALO_ICON_SRC=${pkgs.papirus-icon-theme}/share/icons
    export HALO_ARCTIC_SRC=${inputs.arcticons}/icons/white
    exec ${pkgs.python3}/bin/python3 ${./halo-recolor-icons.py} "$@"
  '';
  # halo-set-pin: choose the lock-screen PIN (4-8 digits). Stored salted+hashed in ~/.config/halo/lock.json.
  haloSetPin = pkgs.writeShellApplication {
    name = "halo-set-pin";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      read -r -s -p "New PIN (4-8 digits): " p1; echo
      read -r -s -p "Repeat PIN: " p2; echo
      if [ "$p1" != "$p2" ]; then echo "PINs differ"; exit 1; fi
      case "$p1" in (*[!0-9]*|"") echo "Digits only"; exit 1;; esac
      n=''${#p1}
      if [ "$n" -lt 4 ] || [ "$n" -gt 8 ]; then echo "Use 4 to 8 digits"; exit 1; fi
      salt=$(head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n')
      hash=$(printf '%s%s' "$salt" "$p1" | sha256sum | cut -d' ' -f1)
      mkdir -p "$HOME/.config/halo"
      umask 077
      printf '{"salt":"%s","hash":"%s","len":%s}\n' "$salt" "$hash" "$n" > "$HOME/.config/halo/lock.json"
      echo "PIN saved."
    '';
  };
  # halo-autokbd: tablet when no real keyboard is attached, desktop when one is (Type Cover, Bluetooth, USB).
  #   halo-autokbd count   -> list the keyboards it sees (udev ID_INPUT_KEYBOARD=1) and exit
  #   halo-autokbd         -> watch input hot-plug (debounced) and call set_mode when the keyboard set flips
  haloAutoKbd = pkgs.writeShellApplication {
    name = "halo-autokbd";
    runtimeInputs = [ config.programs.hyprland.package pkgs.coreutils pkgs.findutils pkgs.systemd ];
    text = ''
      # A real keyboard has the letter keys (KEY_Q=16, KEY_A=30, KEY_Z=44, KEY_SPACE=57).
      # Power/volume buttons (gpio-keys), lid and video bus do not.
      list() {
        local ev words w v b ok
        for ev in /sys/class/input/event*; do
          [ -r "$ev/device/capabilities/key" ] || continue
          read -r -a words < "$ev/device/capabilities/key" || continue
          [ "''${#words[@]}" -gt 0 ] || continue
          w=''${words[-1]}
          v=$((16#$w))
          ok=1
          for b in 16 30 44 57; do
            if [ $(( (v >> b) & 1 )) -eq 0 ]; then ok=0; fi
          done
          if [ "$ok" -eq 1 ]; then cat "$ev/device/name"; fi
        done
      }

      if [ "''${1:-}" = "count" ]; then
        list
        echo "keyboards: $(list | wc -l)"
        exit 0
      fi

      if [ -z "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        HYPRLAND_INSTANCE_SIGNATURE=$(find "/run/user/$(id -u)/hypr" -mindepth 1 -maxdepth 1 -type d ! -name chronos-shell -printf '%f\n' | head -1)
        export HYPRLAND_INSTANCE_SIGNATURE
      fi

      last=""
      apply() {
        local n want
        n=$(list | wc -l)
        if [ "$n" -gt 0 ]; then want=desktop; else want=tablet; fi
        # Only act when the keyboard set flips, so a manual toggle wins until then.
        echo "halo-autokbd: $n keyboard(s) -> $want (last: ''${last:-none})" >&2
        if [ "$want" != "$last" ]; then
          if hyprctl eval "set_mode(\"$want\")" > /dev/null; then last=$want; else echo "halo-autokbd: hyprctl eval failed" >&2; fi
        fi
      }

      for _ in 1 2 3 4 5 6 7 8 9 10; do
        apply
        [ -n "$last" ] && break
        sleep 2
      done

      udevadm monitor --udev --subsystem-match=input | while read -r _; do
        while read -r -t 1.5 _; do :; done
        apply
      done
    '';
  };
in
{
  options.modules.desktop.autoMode = lib.mkEnableOption "automatic tablet/desktop mode from attached keyboards (halo-autokbd)";
  config = lib.mkIf (cfg.shell == "halo") {
    environment.systemPackages = [
      haloCtl
      haloRecolorIcons
      haloSetPin
      haloAutoKbd
      haloApp
      (haloAppEntry "files" "Files" "system-file-manager" "Utility")
      (haloAppEntry "gallery" "Gallery" "image-x-generic" "Graphics")
      (pkgs.makeDesktopItem {
        name = "halo-settings";
        desktopName = "Settings";
        exec = "halo-ctl call settings open";
        icon = "preferences-system";
        categories = [ "Settings" ];
        startupWMClass = "halo-settings";
      })
      pkgs.glib # gio trash (Files, Gallery)
      pkgs.xdg-utils # xdg-open
      pkgs.zip # Files: compress / extract
      pkgs.unzip
      pkgs.p7zip
      pkgs.file # Files: mime type in the info panel
      pkgs.udisks # udisksctl: mount / unmount in Files
      pkgs.imagemagick # Gallery: rotate, EXIF info
      pkgs.ffmpeg # Gallery: video thumbnails, duration
      pkgs.poppler-utils # Files: pdftoppm PDF thumbnails
      pkgs.wl-clipboard # wl-copy (Files, Gallery)
      pkgs.dbus # dbus-monitor: lock before suspend
      pkgs.brightnessctl # shade brightness slider
      pkgs.wireplumber # wpctl (volume)
      pkgs.networkmanager # nmcli (Wi-Fi tile)
      pkgs.bluez # bluetoothctl (Bluetooth tile)
      pkgs.grim # screenshot tile
      pkgs.slurp # region screenshot tile
      pkgs.wf-recorder # screen record tile
      pkgs.hyprsunset # night light tile
      pkgs.libnotify # notify-send
      pkgs.matugen # wallpaper-derived theme colours (Theme.qml)
    ];
    services.udev.packages = [ pkgs.brightnessctl ]; # backlight writable without root
    # Bundled wallpapers (assets/wallpapers) -> /etc/halo/wallpapers; its own store path, so shell edits do not copy them again.
    environment.etc."halo/wallpapers".source = ../../../assets/wallpapers;
    services.upower.enable = lib.mkDefault true; # battery widget
    services.udisks2.enable = lib.mkDefault true; # Files: mount / unmount drives
    services.power-profiles-daemon.enable = lib.mkDefault true; # Settings > Battery > Power mode (powerprofilesctl)
    security.pam.services.halo = { }; # lock screen password check

    systemd.user.services.halo-autokbd = lib.mkIf cfg.autoMode {
      description = "Auto tablet/desktop mode from attached keyboards";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      path = [ config.programs.hyprland.package "/run/current-system/sw" ];
      serviceConfig = {
        ExecStart = lib.getExe haloAutoKbd;
        Restart = "on-failure";
        RestartSec = 3;
      };
    };

    systemd.user.services.halo = {
      description = "Halo shell (Quickshell)";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      # hyprctl, surface-rotate and kbd-toggle must be reachable from the shell
      path = [ config.programs.hyprland.package "/run/current-system/sw" ];
      serviceConfig = {
        ExecStart = launcher;
        Restart = "on-failure";
        RestartSec = 2;
      };
    };
  };
}
