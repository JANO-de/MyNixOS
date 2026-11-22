# Gaming: steam + gamescope, gamemode, and the `all` bundle.
_: {
  flake.nixosModules.gaming =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.modules.gaming;
    in
    {
      options.modules.gaming = {
        all = lib.mkEnableOption "every gaming module (steam, gamemode)";
        steam = lib.mkEnableOption "Steam";
        gamemode = lib.mkEnableOption "GameMode";
      };

      config = lib.mkMerge [
        # Bundle: members use mkDefault, so a host can still turn one off.
        (lib.mkIf cfg.all {
          modules.gaming.steam = lib.mkDefault true;
          modules.gaming.gamemode = lib.mkDefault true;
        })

        (lib.mkIf cfg.gamemode {
          programs.gamemode.enable = true;
          users.users.jano.extraGroups = [ "gamemode" ];
        })

        (lib.mkIf cfg.steam {
          programs.steam = {
            enable = true;
            remotePlay.openFirewall = true;
            localNetworkGameTransfers.openFirewall = true;
            gamescopeSession.enable = true;
            platformOptimizations.enable = true;
          };
          programs.gamescope = {
            enable = true;
            capSysNice = true;
          };
          hardware.graphics.enable32Bit = true;
          nix.settings = {
            substituters = [ "https://nix-gaming.cachix.org" ];
            trusted-public-keys = [ "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4=" ];
          };
          environment.systemPackages = [
            pkgs.xwayland-satellite
            pkgs.vulkan-tools
          ];
        })
      ];
    };
}
