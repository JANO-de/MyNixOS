# niri (the chronos fork), used by the Surface. Config: ./niri.kdl with the theme
# colors and the shell's binds filled in, validated at build time.
{ config, lib, pkgs, inputs, theme, ... }:

let
  cfg = config.modules.desktop;

  shellBinds = lib.optionalString (cfg.shell == "dynisland") ''
    Mod+Space   { spawn "dynisland" "ipc" "launcher" "toggle"; }
    Alt+Space   { spawn "dynisland" "ipc" "spotlight" "toggle"; }
    Mod+Shift+L { spawn "dynisland" "ipc" "lock" "lock"; }
    Mod+Q       { spawn "dynisland" "ipc" "quick" "toggle"; }
    Mod+V       { spawn "dynisland" "ipc" "tools" "clipboard"; }
    Mod+Ctrl+E  { spawn "dynisland" "ipc" "tools" "emoji"; }
    Mod+Shift+C { spawn "dynisland" "ipc" "tools" "color"; }
    Mod+A       { spawn "dynisland" "ipc" "ai" "toggle"; }
    Mod+Comma   { spawn "dynisland" "ipc" "settings" "toggle"; }
    Mod+I       { spawn "dynisland" "ipc" "island" "toggle"; }
  '';

  content =
    lib.replaceStrings
      [
        "@FOCUS@"
        "@FOCUS_INACTIVE@"
        "@SHELL_BINDS@"
        ''spawn-at-startup "polkit-gnome-authentication-agent-1"''
      ]
      [
        (theme.color "accent")
        (theme.color "surface")
        shellBinds
        ''spawn-at-startup "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"''
      ]
      (builtins.readFile ./niri.kdl);
in
{
  config = lib.mkIf (cfg.session == "niri") {
    programs.niri = {
      enable = true;
      package = inputs.chronos.packages.${pkgs.stdenv.hostPlatform.system}.niri; # the fork, NOT stock niri
    };

    environment.systemPackages = with pkgs; [
      polkit_gnome
      xwayland-satellite # niri auto-spawns it on demand for X11 apps
    ];

    home-manager.users.jano.xdg.configFile."niri/config.kdl".source =
      pkgs.runCommand "niri-config-validated"
        {
          nativeBuildInputs = [ pkgs.niri ];
          passAsFile = [ "content" ];
          inherit content;
        }
        ''
          niri validate --config "$contentPath"
          cp "$contentPath" $out
        '';
  };
}
