# Dux Greeter (greetd login screen with the Dux Shell look). OFF by default.
# Replaces SDDM: enable it on one host first
# (modules.dux.greeter.enable = true;) and keep the previous generation in the boot menu.
# UNVERIFIED: the option below is the nixpkgs 26.05 module name from the pre-rename DankGreeter docs;
# if the rebuild says it does not exist, check `nixos-option services.displayManager` for the new name.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.dux.greeter;
in
{
  options.modules.dux.greeter.enable = lib.mkEnableOption "Dux Greeter (replaces SDDM)";

  config = lib.mkIf cfg.enable {
    services.displayManager.sddm.enable = lib.mkForce false;

    programs.sway.enable = true; # the greeter's compositor must be installed system-wide

    services.displayManager.dms-greeter = {
      enable = true;
      # Not hyprland: its Lua config (0.56+) rejects the classic-syntax config the greeter generates.
      compositor.name = "sway";
      configHome = "/home/jano"; # sync the user's Dux Shell theme with the greeter
      quickshell.package = pkgs.quickshell;
    };

    # The greeter runs its own Hyprland as user dms-greeter, which starts graphical-session.target and
    # with it every global user service (full shell, files, sunshine, deskflow). Keep those for real users.
    systemd.user.services = lib.genAttrs (
      [
        "dms"
        "dfiles"
      ]
      ++ lib.optional config.modules.services.sunshine.enable "sunshine"
      ++ lib.optional (config.modules.programs.deskflow.role == "server") "deskflow-server"
      ++ lib.optional (config.modules.programs.deskflow.role == "client") "deskflow-client"
    ) (_: {
      unitConfig.ConditionUser = "!dms-greeter";
    });
  };
}
