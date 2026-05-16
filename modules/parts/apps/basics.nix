{ self, inputs, ... }: {
  flake.nixosModules.basicApps = { pkgs, lib, ... }: {
    environment.systemPackages = with pkgs; [
# --- INTERFAZ Y SISTEMA (Niri / KDE / GNOME) ---
      kdePackages.sddm-kcm
      sddm-sugar-dark
      sddm-astronaut
      polkit_gnome
      xdg-desktop-portal-gtk
      gnome-tweaks
      gnome-shell-extensions
      plymouth
      adi1090x-plymouth-themes
      libnotify
      dunst
      eww
      matugen
      wmctrl
      kando
      heimdall
      lz4
      gnomeExtensions.gpu-profile-selector # hybrid graphics management

      # --- LIBRERÍAS QT & COMPATIBILIDAD ---
      kdePackages.qt5compat
      kdePackages.qtsvg
      kdePackages.qtdeclarative
      kdePackages.qtimageformats
      kdePackages.qtmultimedia

      # --- DESARROLLO Y LENGUAJES ---
      python315
      python314
      javaPackages.compiler.openjdk25
      javaPackages.compiler.openjdk17
      javaPackages.compiler.openjdk8
      jetbrains.idea
      eclipses.eclipse-java
      bluej
      vscode
      git
      direnv
      jq
      yq-go
      R

      # --- GAMING ---
      bazaar
      ryubing
      mangohud
      protonup-ng
      lutris
      bottles
      heroic
      steam-run
      wine
      prismlauncher
      heroic
      gogdl

      # --- NAVEGACIÓN Y COMUNICACIÓN ---
      floorp-bin
      pywalfox-native
      whatsapp-electron
      vesktop
      telegram-desktop
      tor-browser

      # --- GESTIÓN DE ARCHIVOS Y COMPRESIÓN ---
      nautilus
      kdePackages.ark
      unrar
      rar
      unzip
      zip
      p7zip
      file

      # --- HERRAMIENTAS DE TERMINAL (CLI) ---
      kitty
      vim
      idevicerestore
      wget
      curl
      fzf
      killall
      btop
      fastfetch
      taskwarrior3
      yt-dlp

      # --- ANDROID Y MÓVIL ---
      #mtkclient
      #android-tools
      #universal-android-debloater

      # --- MULTIMEDIA Y CAPTURA ---
      monophony
      pavucontrol
      playerctl
      mpvpaper
      ffmpeg
      satty
      imagemagick
      grim
      grimblast
      slurp
      swappy
      wl-clipboard
      cliphist
      mpv
      jq

      # --- PRODUCTIVIDAD Y OFICINA ---
      #libreoffice-qt-fresh
      penpot-desktop
      pkgs.onlyoffice-desktopeditors
      gnucash
      papers
      obsidian
      evolution
      hunspell
      hunspellDicts.es_ES
      hunspellDicts.en_US

      # --- OTROS ---
      antigravity
      pkgs.ollama
      (import inputs.nixpkgs-unstable { system = pkgs.system; config.allowUnfree = true; }).claude-code
      qbittorrent
      cups
      evtest
      libusb-compat-0_1
      mtkclient
      pkgs.icu
      usbmuxd
      
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

    programs.appimage.enable = true;
    programs.appimage.binfmt = true;
    programs.appimage.package = pkgs.appimage-run.override 
    {
      extraPkgs = pkgs: 
      [
        pkgs.icu
        pkgs.libxcrypt-legacy
        pkgs.python312
        pkgs.python312Packages.torch
      ]; 
    };

    fonts.packages = with pkgs; [
      corefonts
    ];
  };
} 
