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

  # obsidian-sync-colors — keep the Obsidian "ITS Theme" colors in sync with
  # the same iNiR Material You palette. The vault theme routes its color
  # variables through --inir-* custom properties whose fallbacks are the stock
  # ITS colors; this script derives those tokens from the generated palette,
  # writes them to .obsidian/snippets/inir-theme.css and enables the snippet in
  # appearance.json, so the theme is untouched when iNiR has no palette yet.
  obsidianSyncColors = pkgs.writeShellScriptBin "obsidian-sync-colors" (builtins.readFile ./scripts/obsidian-sync-colors);

  # Optional daily notifier: checks whether origin/main has commits not yet
  # pulled into the local flake repo. Adapted from the reference repo to point
  # at this flake instead of the stock /etc/nixos layout.
  configNotifier = pkgs.writeShellScriptBin "check-config-updates" (builtins.readFile ./scripts/check-config-updates.sh);

  # Optional weekly auto-updater: pulls origin/main and rebuilds ONLY if the
  # clone is clean and the build succeeds, rolling back the checkout otherwise.
  configAutoUpdater = pkgs.writeShellScriptBin "auto-update" (builtins.readFile ./scripts/auto-update.sh);

  # Monitor Manager — a standalone Quickshell window plus an iNiR settings page
  # for arranging niri outputs, and named layout profiles.
  #
  # The upstream iNiR package hard-codes its settings page list, so the page has
  # to be spliced into the packaged runtime rather than dropped in as an overlay.
  # overrideAttrs is used rather than copying the output so that the upstream
  # runtimeDependencies/propagatedBuildInputs survive: the shell is launched
  # with the package's own dependency PATH, and losing those would break it.
  inirBase = inputs.inir.packages.${pkgs.stdenv.hostPlatform.system}.default;

  inirWithMonitorManager = inirBase.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];

    postInstall = ''
      runtime="$out/share/quickshell/inir"

      # The settings page imports the shared UI as the `qs.monitorManager`
      # module, so that directory needs its qmldir. The name is camelCase
      # because QML import URIs reject hyphens. The page itself lives in its own
      # directory so the standalone launch never scans its qs.* imports.
      mkdir -p "$runtime/monitorManager" "$runtime/monitor-manager-settings"
      cp ${./monitor-manager}/* "$runtime/monitorManager/"
      cp ${./monitor-manager-settings}/*.qml "$runtime/monitor-manager-settings/"

      # Backend, next to the niri-config.py the shell already knows about.
      install -m 0755 ${./scripts/monitor-manager.py} "$runtime/scripts/monitor-manager.py"

      # Register the settings page. This aborts the build if the upstream
      # registry no longer matches, rather than shipping a page that is
      # silently missing from the settings window.
      python3 ${./inir-monitor-manager}/patch-inir-registry.py \
        "$runtime/modules/settings/SettingsPageRegistry.qml"

      # Standalone launcher for the Mod+Ctrl+M keybind. The pane starts the
      # backend as `python3 <script>`, so python has to be on PATH; the
      # absolute path is passed separately because the settings page inherits
      # the shell's environment instead of this wrapper's.
      makeWrapper ${lib.getExe pkgs.quickshell} "$out/bin/inir-monitor-manager" \
        --add-flags "-p $runtime/monitorManager/MonitorManager.qml" \
        --set-default MONITOR_MANAGER_PY "$runtime/scripts/monitor-manager.py" \
        --prefix PATH : ${lib.makeBinPath [ pkgs.python3 ]}
    '';
  });

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
  # `flock` (settings-window serialization) and `awk` (stage/instance
  # listing) are used by scripts/inir; they are also present on the manager
  # PATH (sw/bin) so both code paths stay covered.
  systemd.user.services.inir.path = [
    (pkgs.python3.withPackages (ps: with ps; [ pip materialyoucolor pillow evdev numpy ]))
    pkgs.jq
    pkgs.cliphist
    pkgs.ddcutil
    pkgs.util-linux
    pkgs.gawk
  ];

  programs.inir = {
    enable = true;
    service.compositor = "niri";
    # Carries the Monitor Manager QML, its backend and the patched settings
    # registry. environment.systemPackages picks up the launcher from here.
    package = inirWithMonitorManager;
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

  # Wallpaper → Obsidian "ITS Theme" color sync, watching the same generated
  # palette directory.
  systemd.user.services.obsidian-sync-colors = {
    description = "Sync Obsidian ITS Theme colors with iNiR generated theme data";
    after = [ "inir.service" ];
    wantedBy = [ "default.target" ];
    path = with pkgs; [
      inotify-tools
      jq
      python3
      # flock (appearance.json serialization) lives in util-linux.
      util-linux
    ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${lib.getExe obsidianSyncColors} --watch";
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