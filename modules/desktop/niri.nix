{ config, inputs, pkgs, lib, ... }:
let
  inir = inputs.inir.packages.${pkgs.system};

  # The wallpaper color pipeline (switchwall.sh / generate_colors_material.py /
  # system24_palette.py) requires jq plus a python3 with numpy, pillow and
  # materialyoucolor; plain python3 crashes with ModuleNotFoundError.
  inirPython = pkgs.python3.withPackages (ps: [
    ps.numpy
    ps.pillow
    ps.materialyoucolor
  ]);

  # inir 2.30.0's launcher aborts at boot with exit 1 when none of the niri
  # app-environment vars are present in config.kdl: apply_niri_app_environment()
  # ends in a bare `[[ -n "$value" ]] && export ...`, and the loop's non-zero
  # tail status trips the `set -e` session-boot fast-path. Append `|| true`
  # so an empty parsed value can't kill the whole shell.
  fixInirBoot = old: {
    postInstall = (old.postInstall or "") + ''
      sed -i '/&& export "/s/$/ || true/' "$out/share/quickshell/inir/scripts/inir"
      # scripts/inir replaces the systemd unit PATH with the user manager's login
      # PATH (upstream Arch-oriented). Re-append our tool dirs after that merge;
      # INIR_EXTRA_PATH is injected via unit Environment.
      sed -i 's|^[[:space:]]*export PATH="\$_qs_merged"$|&; export PATH="$PATH''${INIR_EXTRA_PATH:+:$INIR_EXTRA_PATH}"|' "$out/share/quickshell/inir/scripts/inir"
    '';
  };

  # inir's theme pipeline discovers modules/targets with `find -type f`, which
  # silently skips the symlinks a symlinkJoin exposes — so no theming module
  # (terminals incl. alacritty, GTK, ...) would ever run. Build a merged tree
  # of REAL files instead.
  inir-with-mascot = (pkgs.runCommand "inir-with-mascot-${inir.inir.version}" { } ''
    mkdir -p "$out"
    cp -rL --no-preserve=mode ${inir.inir.overrideAttrs fixInirBoot}/* "$out"/
    cp -rL --no-preserve=mode ${inir.inir-mascot}/* "$out"/
    find "$out" -type d -exec chmod 755 {} +
    find "$out" -type f -exec chmod 644 {} +
    chmod +x "$out/bin/inir"
    find "$out/share/quickshell/inir" -type f \( -name '*.sh' -o -name '*.py' \) -exec chmod +x {} +
  '').overrideAttrs ({ meta ? { }, ... }: {
    # runCommand doesn't propagate mainProgram; the NixOS module resolves the
    # service binary via lib.getExe and would otherwise target a missing
    # bin/inir (ExecStart 203/EXEC).
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

  # The inir module feeds extraPackages into the unit's `path=`, but systemd
  # only uses that for executable lookup — the running shell's $PATH stays the
  # stock login PATH, so every scripted spawn (python3, magick, jq, ...) fails
  # with "binary could not be found". Set PATH explicitly via Environment.
  inirProcPath = lib.makeBinPath ([
    inir-with-mascot
    config.programs.niri.package
    pkgs.awww
    pkgs.jq
    inirPython
    pkgs.ffmpeg
    pkgs.imagemagick
  ]);
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
    # The wallpaper auto-theme pipeline (switchwall.sh) hard-exits without jq,
    # and its color generator needs a python3 with numpy/pillow/materialyoucolor.
    # ffmpeg + imagemagick cover the "vibrant" dominant-color extraction and
    # thumbnail generation.
    extraPackages = [
      config.programs.niri.package
      pkgs.awww
      pkgs.jq
      inirPython
      pkgs.ffmpeg
      pkgs.imagemagick
    ];
    package = inir-with-mascot;
  };

  systemd.tmpfiles.rules = awwwFhsSymlinks;

  # Expose KDE kirigami-addons QML components (formcard & co) to the shell's
  # QML engine; the inir launcher prepends its own qml deps via --prefix, so
  # both search paths are honored.
  systemd.user.services.inir.environment = {
    PATH = lib.mkForce (inirProcPath + ":/run/wrappers/bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin");
    INIR_EXTRA_PATH = inirProcPath;
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
