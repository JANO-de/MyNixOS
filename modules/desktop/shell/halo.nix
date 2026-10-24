{ config, lib, pkgs, ... }:
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
in
{
  config = lib.mkIf (cfg.shell == "halo") {
    environment.systemPackages = [
      haloCtl
      haloSetPin
      pkgs.dbus # dbus-monitor: lock before suspend
      pkgs.brightnessctl # shade brightness slider
      pkgs.wireplumber # wpctl (volume)
      pkgs.networkmanager # nmcli (Wi-Fi tile)
      pkgs.bluez # bluetoothctl (Bluetooth tile)
      pkgs.grim # screenshot tile
      pkgs.libnotify # notify-send
    ];
    services.udev.packages = [ pkgs.brightnessctl ]; # backlight writable without root
    # Bundled wallpapers (assets/wallpapers) -> /etc/halo/wallpapers; its own store path, so shell edits do not copy them again.
    environment.etc."halo/wallpapers".source = ../../../assets/wallpapers;
    services.upower.enable = lib.mkDefault true; # battery widget
    security.pam.services.halo = { }; # lock screen password check

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
