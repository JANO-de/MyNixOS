# Compositor switch: modules.desktop.compositor = "niri" | "mangowm" | "none".
# Noctalia runs on both. Under niri it is a systemd user unit (niri.service pulls in
# graphical-session.target). mangowm never starts that target, so Noctalia is launched
# from mango's own config (exec-once), see hosts/<host>/dotfiles/mango.
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
    description = "Compositor installed and offered at the login screen. Noctalia is the shell on both.";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf (cfg.compositor != "none") {
        programs.noctalia = {
          enable = true;
          package = inputs.noctalia.packages.${sys}.default;
          recommendedServices.enable = true;
        };
      })
      (lib.mkIf (cfg.compositor == "niri") {
        programs.niri.enable = true;
        programs.niri.package = pkgs.niri;
        programs.noctalia.systemd.enable = true;
        services.displayManager.defaultSession = "niri";
      })
      (lib.mkIf (cfg.compositor == "mangowm") {
        programs.mango.enable = true;
        environment.systemPackages = [
          pkgs.foot
          pkgs.rofi
        ];
      })
    ]
  );
}
