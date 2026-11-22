# ytm-player (programs.ytm-player.enable): YouTube Music TUI, packaged by its upstream flake.
_: {
  flake.nixosModules.programs-ytm-player =
    {
      config,
      lib,
      inputs,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.ytm-player;
      system = pkgs.stdenv.hostPlatform.system;
    in
    {
      options.programs.ytm-player = {
        enable = lib.mkEnableOption "ytm-player, YouTube Music TUI";
        package = lib.mkOption {
          type = lib.types.package;
          default = inputs.ytm-player.packages.${system}.default;
          description = "Use ytm-player-full for Discord, Last.fm and Spotify import.";
        };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ cfg.package ];
      };
    };
}
