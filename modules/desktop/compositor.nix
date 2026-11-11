# Compositor switch: modules.desktop.compositor = "niri" | "mangowm" | "none".
# The shell (bar, panels, notifications) is chosen separately in shell.nix.
# niri.service pulls in graphical-session.target, so shell units start with it. mangowm never
# starts that target, so mango launches `desktop-shell` itself (exec-once in hosts/<host>/dotfiles/mango).
# kitty (terminal) and rofi (launcher) are installed for both compositors.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.modules.desktop;
  sys = pkgs.stdenv.hostPlatform.system;
in
{
  options.modules.desktop.compositor = lib.mkOption {
    type = lib.types.enum [
      "niri"
      "mangowm"
      "none"
    ];
    default = "none";
    description = "Compositor installed and offered at the login screen. The shell is modules.desktop.shell.";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf (cfg.compositor != "none") {
        environment.systemPackages = [
          pkgs.kitty
          pkgs.rofi
        ];
      })
      (lib.mkIf (cfg.compositor == "niri") {
        programs.niri.enable = true;
        programs.niri.package = inputs.niri-flake.packages.${sys}.niri-unstable;
        services.displayManager.defaultSession = "niri";
      })
      (lib.mkIf (cfg.compositor == "mangowm") {
        programs.mango.enable = true;
      })
    ]
  );
}
