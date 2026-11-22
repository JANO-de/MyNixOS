# Shell switch: modules.desktop.shell = "noctalia" | "none".
# The shell is the bar, panels, notifications and wallpaper layer (Noctalia v5, C++). It runs as
# a systemd user unit that niri.service pulls in through graphical-session.target.
_: {
  flake.nixosModules.desktop-shell =
    {
      config,
      lib,
      pkgs,
      inputs,
      ...
    }:
    let
      cfg = config.modules.desktop;
      noctalia = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {
      options.modules.desktop.shell = lib.mkOption {
        type = lib.types.enum [
          "noctalia"
          "none"
        ];
        default = "noctalia";
        description = "Shell started in the session. Needs a compositor; \"none\" starts no shell.";
      };

      config = lib.mkIf (cfg.enable && cfg.compositor != "none" && cfg.shell == "noctalia") {
        programs.noctalia = {
          enable = true;
          package = noctalia;
          systemd.enable = true;
        };
      };
    };
}
