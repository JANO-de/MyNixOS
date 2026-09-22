{ config, inputs, pkgs, lib, ... }:
let

  # niri-sync-colors — keep the iNiR-generated Material You palette in sync
  # with Niri's focus-ring colors and the shell's wallpaper path.
  #
  # NOTE: the reference script edits ~/.config/niri/config.kdl via
  # niri-config.py. Here that file is a read-only home-manager store symlink,
  # so the niri part is applied on a writable copy when possible and skipped
  # gracefully otherwise; the wallpaper path sync always runs.
  niriSyncColors = pkgs.writeShellScriptBin "niri-sync-colors" (builtins.readFile ./scripts/niri-sync-colors);

  # Optional daily notifier: checks whether origin/main has commits not yet
  # pulled into the local flake repo. Adapted from the reference repo to point
  # at this flake instead of the stock /etc/nixos layout.
  configNotifier = pkgs.writeShellScriptBin "check-config-updates" (builtins.readFile ./scripts/check-config-updates.sh);

  # Optional weekly auto-updater: pulls origin/main and rebuilds ONLY if the
  # clone is clean and the build succeeds, rolling back the checkout otherwise.
  configAutoUpdater = pkgs.writeShellScriptBin "auto-update" (builtins.readFile ./scripts/auto-update.sh);

in {

  imports = [
    inputs.inir.nixosModules.inir
  ];

  programs.dconf.enable = true;

  # Fixes scripts inside iNiR that call /bin/cat directly (FHS assumption).
  # NixOS has no /bin/cat by default; iNiR's battery/threshold scripts break
  # without this symlink.
  systemd.tmpfiles.rules = [
    "L+ /bin/cat - - - - ${pkgs.coreutils}/bin/cat"
  ];

  # extraPackages (inside `programs.inir`) wires the Qt plugin/QML search
  # paths; the inir user service's own $PATH is a short fixed list, so the
  # interpreter-tools the shell spawns internally must be declared here too.
  systemd.user.services.inir.path = [
    (pkgs.python3.withPackages (ps: with ps; [ pip materialyoucolor pillow evdev numpy ]))
    pkgs.jq
    pkgs.cliphist
    pkgs.ddcutil
  ];

  programs.inir = {
    enable = true;
    service.compositor = "niri";
    extraPackages = import ./modules/inir-deps.nix { inherit pkgs; };
  };

  # Wallpaper → Niri color sync, watching the iNiR-generated palette
  systemd.user.services.niri-sync-colors = {
    description = "Sync Niri colors and iNiR wallpaper with generated theme data";
    after = [ "inir.service" ];
    wantedBy = [ "default.target" ];
    path = with pkgs; [
      inotify-tools
      jq
      python3
    ];
    environment = {
      # The reference copies niri-config.py to ~/.config/quickshell/inir/scripts
      # during its manual install step; here it lives in the inir package store
      # path, which home-manager would otherwise not have as a normal file.
      NIRI_CONFIG_PY = "${config.programs.inir.package}/share/quickshell/inir/scripts/niri-config.py";
    };
    serviceConfig = {
      Type = "simple";
      ExecStart = "${lib.getExe niriSyncColors} --watch";
      Restart = "always";
      RestartSec = 2;
    };
  };

  # Optional daily "config updates available" notifier (opt-in)
  systemd.user.timers.check-config-updates = {
    description = "Daily check for NixOS config repo updates";
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "1d";
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
  };
  systemd.user.services.check-config-updates = {
    description = "Check for NixOS config repository updates";
    path = with pkgs; [ git libnotify ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${lib.getExe configNotifier}";
    };
  };

  # Optional weekly auto-updater (opt-in — enable by adding `enable = true` to
  # systemd.user.timers.auto-update or running `systemctl --user enable --now auto-update.timer`)
  systemd.user.timers.auto-update = {
    description = "Weekly automatic NixOS config update (opt-in)";
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
  };
  systemd.user.services.auto-update = {
    description = "Automatic NixOS config update (opt-in)";
    path = with pkgs; [ git libnotify ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${lib.getExe configAutoUpdater}";
    };
  };

  # Optional but recommended: a login manager. Keep the SDDM greeter from
  # modules/desktop/plasma.nix (the reference enables GDM, which we don't use).
  services.xserver.enable = true;

}