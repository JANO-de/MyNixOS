{ self, inputs, ... }: {
  flake.nixosModules.basicApps = { pkgs, lib, ... }: {
    environment.systemPackages = with pkgs; [
      git
      polkit_gnome
      vim
      wget
      curl
      direnv
      firefox
      librewolf
      kdePackages.kate
      kitty             # Terminal for Niri
      pavucontrol       # Audio control GUI
      libnotify         # Notifications
      nemo
      vscode
      vesktop
    ];
  };
    
}