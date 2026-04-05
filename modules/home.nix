{ inputs, self, ... }: {
  flake.nixosModules.home = { pkgs, lib, config, ... }: {
    imports = [ inputs.home-manager.nixosModules.home-manager ];

    home-manager.backupFileExtension = "backup";
    home-manager.users.jano = {
      imports = [ 
        inputs.noctalia.homeModules.default
        inputs.niri.homeModules.niri
      ];

      home.packages = with pkgs; [
        # Add any additional packages you want in your home environment here
      ];

      programs.noctalia-shell = {
        enable = true;
        settings = builtins.readFile ./parts/base/noctalia-shell/config.json;
      };

      programs.niri = {
        enable = true;
        # Use the package from your flake if you have a custom one
        package = pkgs.niri; 

        settings = {
          # Using spawn-at-startup here is great for Nix-path resolution
          spawn-at-startup = [ "noctalia-shell ipc call lockScreen toggle" ];

          binds = with config.lib.niri; {
            "Mod+Q".action = close-window;
            "Mod+F".action = maximize-column;
          };
        };

        # This imports your manual config.kdl
        # PRO TIP: Put your keybinds and complex layout rules in the .kdl file
        # and keep the "Nix-dependent" paths in the 'settings' block above.
        config = builtins.readFile ./parts/base/niri/config.kdl;
      };

      home.stateVersion = "25.11"; 
    };
  };
}
