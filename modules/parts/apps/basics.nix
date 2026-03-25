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
      nemo
      kdePackages.dolphin
      kando

      steam
      bazaar

      firefox
      librewolf
      kdePackages.kate
    
      whatsapp-electron
      vscode
      vesktop

      mtkclient
      android-tools
      
      unrar
      kdePackages.ark
      unzip
      zip
      rar

      python315

      javaPackages.compiler.openjdk25
      javaPackages.compiler.openjdk17
      javaPackages.compiler.openjdk8

      # Screenshotting
      wl-clipboard
      cliphist
      imagemagick
      dunst
      grim
      grimblast
      slurp
      swappy
      
    ];

    programs.kdeconnect.enable = true;
  };
} 