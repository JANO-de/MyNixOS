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
      nautilus
      kando
 
      # Gaming
      steam
      bazaar
      mangohud
      protonup-ng
      lutris
      bottles
      heroic

      # Browsers
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
      eclipses.eclipse-java
      bluej

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
      steam.enable = true;
      steam.gamescopeSession.enable = true;
      gamemode.enable = true;

    };

    environment.sessionVariables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = 
        "/home/jano/.steam/root/compatibilitytools.d";
    };
  };
} 