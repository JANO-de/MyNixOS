{ config, inputs, pkgs, lib, ... }:
let
  inir = inputs.inir.packages.${pkgs.system};

  # inir 2.30.0's launcher aborts at boot with exit 1 when none of the niri
  # app-environment vars are present in config.kdl: apply_niri_app_environment()
  # ends in a bare `[[ -n "$value" ]] && export ...`, and the loop's non-zero
  # tail status trips the `set -e` session-boot fast-path. Append `|| true`
  # so an empty parsed value can't kill the whole shell.
  fixInirBoot = old: {
    postInstall = (old.postInstall or "") + ''
      sed -i '/&& export "/s/$/ || true/' "$out/share/quickshell/inir/scripts/inir"
    '';
  };

  inir-with-mascot = (pkgs.symlinkJoin {
    name = "inir-with-mascot-${inir.inir.version}";
    paths = [ (inir.inir.overrideAttrs fixInirBoot) inir.inir-mascot ];
  }).overrideAttrs ({ meta ? { }, ... }: {
    # symlinkJoin doesn't propagate mainProgram; the NixOS module resolves the
    # service binary via lib.getExe and would otherwise target a missing
    # bin/inir-with-mascot (ExecStart 203/EXEC).
    meta = meta // { mainProgram = "inir"; };
  });

  # inir's AwwwBackend probes awww through hardcoded FHS paths via
  # /usr/bin/bash; neither exists on NixOS, so it always reports
  # "awww is not detected in path" regardless of the service PATH.
  awwwFhsSymlinks = [
    "L+ /usr/bin/bash - - - - ${pkgs.bash}/bin/bash"
    "L+ /usr/bin/awww - - - - ${pkgs.awww}/bin/awww"
    "L+ /usr/bin/awww-daemon - - - - ${pkgs.awww}/bin/awww-daemon"
    "L+ /usr/local/bin/awww - - - - ${pkgs.awww}/bin/awww"
    "L+ /usr/local/bin/awww-daemon - - - - ${pkgs.awww}/bin/awww-daemon"
  ];
in {
  imports = [
    inputs.inir.nixosModules.inir
  ];

  programs.niri = {
    enable = true;
  };

  programs.inir = {
    enable = true;
    service.compositor = "niri";
    extraPackages = [ config.programs.niri.package pkgs.awww ];
    package = inir-with-mascot;
  };

  systemd.tmpfiles.rules = awwwFhsSymlinks;

  # Expose KDE kirigami-addons QML components (formcard & co) to the shell's
  # QML engine; the inir launcher prepends its own qml deps via --prefix, so
  # both search paths are honored.
  systemd.user.services.inir.environment = {
    QML2_IMPORT_PATH = lib.makeSearchPath "lib/qt-6/qml" [ pkgs.kdePackages.kirigami-addons ];
    QT_PLUGIN_PATH = lib.makeSearchPath "lib/qt-6/plugins" [ pkgs.kdePackages.kirigami-addons ];
  };

  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/desktop/interface".icon-theme = "Papirus-Dark";
    }
  ];

  # Electron apps (vscode, discord, ...) run natively on Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Polkit auth agent for the niri session (no NixOS module exists anymore)
  security.polkit.enable = true;

  environment.systemPackages = with pkgs; [
    polkit_gnome # launched via spawn-at-startup in the niri config
    xwayland-satellite # niri 25.08+ auto-spawns this on-demand for X11 apps (Steam)
    brightnessctl # Fn brightness keys (XF86MonBrightness*)
    playerctl # Fn media keys (XF86AudioPlay/Next/Prev)
  ];
}
