# Hyprland session (Lua config, Hyprland >= 0.55), launched through UWSM so
# graphical-session.target (and with it the dynisland user service) comes up.
# Config template: ./hyprland.lua.
#
# Uses the Hyprland FLAKE package (plugins must match its exact version), so the
# Cachix cache is configured here, ALWAYS on. Do not override the flake's nixpkgs.
{ config, lib, pkgs, inputs, theme, ... }:

let
  cfg = config.modules.desktop;
  sys = pkgs.stdenv.hostPlatform.system;
  hypr = inputs.hyprland.packages.${sys};
  hyprNixpkgs = inputs.hyprland.inputs.nixpkgs.legacyPackages.${sys};

  rgba = key: "rgba(${lib.removePrefix "#" (theme.color key)}ff)";

  screenshot = pkgs.writeShellScript "screenshot" ''
    dir="$HOME/Pictures/Screenshots"
    mkdir -p "$dir"
    f="$dir/Screenshot from $(date +'%Y-%m-%d %H-%M-%S').png"
    g="$(${pkgs.slurp}/bin/slurp)" && [ -n "$g" ] \
      && ${pkgs.grim}/bin/grim -g "$g" "$f" \
      && ${pkgs.wl-clipboard}/bin/wl-copy < "$f"
  '';

  # same shell binds as mango.nix / niri.nix
  shellBinds = lib.optionalString (cfg.shell == "dynisland") (
    lib.concatMapStringsSep "\n"
      (b: ''hl.bind("${b.key}", hl.dsp.exec_cmd("dynisland ipc ${b.ipc}"))'')
      [
        { key = "SUPER + space"; ipc = "launcher toggle"; }
        { key = "ALT + space"; ipc = "spotlight toggle"; }
        { key = "SUPER + SHIFT + L"; ipc = "lock lock"; }
        { key = "SUPER + Q"; ipc = "quick toggle"; }
        { key = "SUPER + V"; ipc = "tools clipboard"; }
        { key = "SUPER + CTRL + E"; ipc = "tools emoji"; }
        { key = "SUPER + SHIFT + C"; ipc = "tools color"; }
        { key = "SUPER + A"; ipc = "ai toggle"; }
        { key = "SUPER + comma"; ipc = "settings toggle"; }
        { key = "SUPER + I"; ipc = "island toggle"; }
      ]
  );

  content =
    lib.replaceStrings
      [ "@ACCENT@" "@SURFACE@" "@POLKIT@" "@SCREENSHOT@" "@WPCTL@" "@SHELL_BINDS@" ]
      [
        (rgba "accent")
        (rgba "surface")
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
        "${screenshot}"
        "${pkgs.wireplumber}/bin/wpctl"
        shellBinds
      ]
      (builtins.readFile ./hyprland.lua);
in
{
  config = lib.mkMerge [
    # The cache must be active BEFORE the flake package is built, so this is not
    # gated on the session. First build: pass the same values on the CLI (see plan).
    {
      nix.settings = {
        substituters = [ "https://hyprland.cachix.org" ];
        trusted-substituters = [ "https://hyprland.cachix.org" ];
        trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
      };
    }

    (lib.mkIf (cfg.session == "hyprland") {
      programs.hyprland = {
        enable = true;
        withUWSM = true; # session entry: "hyprland-uwsm"
        package = hypr.hyprland;
        portalPackage = hypr.xdg-desktop-portal-hyprland;
      };

      # The flake is built against its own nixpkgs: use that Mesa so the GL/GBM
      # libs match (Hyprland wiki, Nix page).
      #hardware.graphics.package = hyprNixpkgs.mesa;

      xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ]; # file picker
      services.gnome.gnome-keyring.enable = true;
      environment.systemPackages = with pkgs; [ polkit_gnome wl-clip-persist ];

      home-manager.users.jano.xdg.configFile."hypr/hyprland.lua".text = content;
    })
  ];
}
