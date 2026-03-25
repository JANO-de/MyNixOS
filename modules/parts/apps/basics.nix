{ self, inputs, ... }: {
  flake.nixosModules.basicApps = { pkgs, lib, ... }: {
    environment.systemPackages = with pkgs; [
      git
      polkit_gnome
      vim
      wget
      curl
      direnv
      kitty             # Terminal for Niri
      pavucontrol       # Audio control GUI
      libnotify         # Notifications

      firefox
      librewolf
      kdePackages.kate
    
      nemo
      vscode
      vesktop
      
      # Screenshotting
      wl-clipboard
      cliphist
      imagemagick
      dunst
      grim
      grimblast
      slurp
      flameshot
      swappy
    ];
  };
} 