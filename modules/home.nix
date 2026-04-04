{ inputs, self, ... }: {
  flake.nixosModules.home = { pkgs, lib, config, ... }: {
    imports = [ inputs.home-manager.nixosModules.home-manager ];

    home-manager.users.jano = {
      imports = [ 
        inputs.noctalia.homeModules.default
        niri.homeModules.niri
      ];

      programs.noctalia-shell = {
        enable = true;
        settings.templates.enableUserTemplates = true;
      };

      programs.niri = {
        enable = true;
        # Use the package from your flake if you have a custom one
        package = pkgs.niri; 

        settings = {
          # Using spawn-at-startup here is great for Nix-path resolution
          spawn-at-startup = [
            "noctalia-shell"
          ];
        };

        # This imports your manual config.kdl
        # PRO TIP: Put your keybinds and complex layout rules in the .kdl file
        # and keep the "Nix-dependent" paths in the 'settings' block above.
        extraConfig = builtins.readFile ./parts/base/niri/config.kdl;
      };

      home.stateVersion = "25.11"; 
    };
  };
}