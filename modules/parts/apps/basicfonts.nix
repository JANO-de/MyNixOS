{ self, inputs, ... }: {
  flake.nixosModules.basicfonts = { pkgs, lib, ... }: {
    fonts.packages = with pkgs; 
    [
      jetbrains-mono
      noto-fonts
      noto-fonts-color-emoji 
      twemoji-color-font
      font-awesome
      powerline-fonts
      powerline-symbols 
    ];
  };
}