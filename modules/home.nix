{ inputs, self, ... }: {
  flake.nixosModules.home = { pkgs, config, astal, ... }: 
  {
    # 1. Import the HM module into NixOS
    imports = [ inputs.home-manager.nixosModules.home-manager ];

    # 2. Define the user-specific config
    home-manager.users.jano = { # Replace 'jano' with your actual username
      imports = [ inputs.ags.homeManagerModules.default ];

      home.packages = with pkgs; [
        # Add any user-specific packages here
        quickshell.packages.{system}.default
      ];
      
      # Home Manager requires these two options to be set
      home.stateVersion = "25.11"; 
    };
  };
}