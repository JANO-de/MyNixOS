{ self, inputs, ... }: {
  flake.nixosModules.basicApps = { pkgs, lib, ... }: {
    environment.systemPackages = with pkgs; [
      kdePackages.qt5compat          # Helps old themes run on Qt6
      kdePackages.qtsvg
      kdePackages.qtdeclarative
      kdePackages.qtimageformats
      kdePackages.qtmultimedia
      kdePackages.qt5compat
      kdePackages.sddm-kcm
      sddm-sugar-dark
      sddm-astronaut
      git
      polkit_gnome
      vim
      wget
      curl
      direnv
      kitty             # Terminal for Niri
      pavucontrol       # Audio control GUI
      libnotify         # Notifications
      nautilus
      kando
      heimdall
      lz4
      plymouth
      adi1090x-plymouth-themes
 
      # Gaming
      bazaar
      mangohud
      protonup-ng
      lutris
      bottles
      heroic

      jq

      # Browsers
      floorp-bin
      pywalfox-native

      kdePackages.kate

      hunspell
      hunspellDicts.es_ES
      hunspellDicts.en_US
    
      whatsapp-electron
      vesktop

      mtkclient
      android-tools
      universal-android-debloater
      
      unrar
      kdePackages.ark
      unzip
      file
      zip
      p7zip
      rar

      # Gnome Office
      libreoffice-qt-fresh
      gnumeric
      gnucash
      dia
      tomboy-ng

      papers
      fastfetch
      gnome-shell-extensions
      playerctl
      satty
      yq-go
      xdg-desktop-portal-gtk
      eww
      mpvpaper
      gnome-tweaks
      ffmpeg
      fzf
      killall
      btop
      taskwarrior3
      matugen
      wmctrl
      steam-run
      qbittorrent
      plymouth
      wine

      python315
      python314
      jetbrains.idea
      eclipses.eclipse-java
      bluej
      vscode
      obsidian
      evtest

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

    programs = {
      
      kdeconnect.enable = true;
      gamemode.enable = true;
      zsh.enable = true;
    };
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true; 
      dedicatedServer.openFirewall = true; 
      localNetworkGameTransfers.openFirewall = true;
      gamescopeSession.enable = true;
    };

    fonts.packages = with pkgs; [
      corefonts
    ];
  };
} 
