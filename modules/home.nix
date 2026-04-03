{ inputs, self, ... }: {
  flake.nixosModules.home = { pkgs, config, astal, ... }: 
  {
    # 1. Import the HM module into NixOS
    imports = [ inputs.home-manager.nixosModules.home-manager ];

    # 2. Define the user-specific config
    home-manager.users.jano = { # Replace 'jano' with your actual username
      imports = [ inputs.ags.homeManagerModules.default ];

      programs.ags = {
        enable = true;
        configDir = ./parts/base/ags;
        extraPackages = with pkgs; [
          inputs.ags.packages.${system}.io
          inputs.ags.packages.${system}.astal4
          inputs.ags.packages.${system}.apps
          inputs.ags.packages.${system}.powerprofiles
          inputs.ags.packages.${system}.auth
          inputs.ags.packages.${system}.battery
          inputs.ags.packages.${system}.bluetooth
          inputs.ags.packages.${system}.cava
          inputs.ags.packages.${system}.greet
          inputs.ags.packages.${system}.mpris
          inputs.ags.packages.${system}.network
          inputs.ags.packages.${system}.notifd
          inputs.ags.packages.${system}.tray
          inputs.astal.packages.${pkgs.stdenv.hostPlatform.system}.battery
          fzf
        ];
      };
      
      # Home Manager requires these two options to be set
      home.stateVersion = "25.11"; 
    };
  };
}