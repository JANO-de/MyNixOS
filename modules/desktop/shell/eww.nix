# Eww island shell for the niri session.
#
# This module is the ONLY bridge between the shell and the rest of the config.
# The shell itself (island bar, notifications, OSD, all scripts) is entirely
# contained in ./eww — edit that folder to change widgets or behaviour. This
# file just:
#   * copies ./eww to ~/.config/eww, baking in the theme colours and the
#     absolute paths to the helper commands (@ISLAND@, @NOTIFY@),
#   * installs the few packages the widgets/scripts call,
#   * starts the eww daemon and the DBus notification server via systemd.
#
# It replaces the wayle shell and is imported only on niri hosts
# (modules/desktop/default.nix gates ./shell on niriEnabled), so the Surface —
# which runs GNOME — is untouched.
{ pkgs, theme, ... }:

let
  c = theme.palette;

  # Python environment for the DBus notification server (code in the folder).
  pythonEnv = pkgs.python3.withPackages (ps: [ ps.dbus-next ]);

  ewwNotify = pkgs.writeShellScriptBin "eww-notify"
    "exec ${pythonEnv}/bin/python3 ${./eww/scripts/notifications.py}";

  # Runnable copies of the helper scripts (the repo files are not executable).
  scripts = pkgs.runCommand "eww-scripts" { } ''
    mkdir -p $out/bin
    install -m 0755 ${./eww/scripts/island} $out/bin/island
    install -m 0755 ${./eww/scripts/osd} $out/bin/osd
    patchShebangs $out/bin
  '';

  islandctl = pkgs.writeShellScriptBin "islandctl" ''exec ${scripts}/bin/island "$@"'';
  osdctl = pkgs.writeShellScriptBin "osdctl" ''exec ${scripts}/bin/osd "$@"'';

  # The self-contained config, deployed verbatim except for the substitutions.
  ewwConfig = pkgs.runCommand "eww-config" { } ''
    cp -r ${./eww} $out
    chmod -R u+w $out
    chmod +x $out/scripts/island $out/scripts/osd $out/scripts/notifications.py
    patchShebangs $out/scripts

    substituteInPlace $out/eww.scss \
      --replace-fail '@BG@'      '${c.base}' \
      --replace-fail '@SURFACE@' '${c.surface0}' \
      --replace-fail '@TEXT@'    '${c.text}' \
      --replace-fail '@SUBTEXT@' '${c.subtext1}' \
      --replace-fail '@ACCENT@'  '${c.mauve}' \
      --replace-fail '@FONT@'    '${theme.fonts.terminal}' \
      --replace-fail '@SANS@'    '${theme.fonts.sans}'

    substituteInPlace $out/eww.yuck \
      --replace-fail '@ISLAND@' '${islandctl}/bin/islandctl' \
      --replace-fail '@NOTIFY@' '${ewwNotify}/bin/eww-notify' \
      --replace-fail '@CONFIG@' "$out"

    substituteInPlace $out/wlogout/style.css \
      --replace-fail '@BG@'     '${c.base}' \
      --replace-fail '@TEXT@'   '${c.text}' \
      --replace-fail '@ACCENT@' '${c.mauve}' \
      --replace-fail '@FONT@'   '${theme.fonts.terminal}'
  '';
in
{
  environment.systemPackages = with pkgs; [
    eww
    islandctl
    osdctl
    wlogout
    libnotify
  ];

  programs.dconf.enable = true;

  home-manager.users.jano = {
    programs.eww = {
      enable = true;
      systemd.enable = true;
    };

    # Whole folder -> ~/.config/eww (read-only store symlink).
    xdg.configFile."eww".source = ewwConfig;

    # Once the daemon is up, open the collapsed island and the (empty)
    # notification window; the OSD is opened on demand by the osd script.
    # The notification server itself needs no unit: the `notifications`
    # deflisten spawns and supervises it, so it must be a single instance.
    systemd.user.services.eww.Service.ExecStartPost =
      "${islandctl}/bin/islandctl init";
  };
}
