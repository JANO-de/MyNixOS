{ self, inputs, ... }: {
  flake.nixosModules.core = { pkgs, ... }: 
  {
    imports = [
      self.nixosModules.basicApps
      self.nixosModules.services
      self.nixosModules.basicfonts
      self.nixosModules.kde
      self.nixosModules.nvidia
      self.nixosModules.boot
      self.nixosModules.theme
    ];

    # (Optional) If you want English menus but Spanish formats (dates/money)
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "es_ES.UTF-8";
      LC_IDENTIFICATION = "es_ES.UTF-8";
      LC_MEASUREMENT = "es_ES.UTF-8";
      LC_MONETARY = "es_ES.UTF-8";
      LC_NAME = "es_ES.UTF-8";
      LC_NUMERIC = "es_ES.UTF-8";
      LC_PAPER = "es_ES.UTF-8";
      LC_TELEPHONE = "es_ES.UTF-8";
      LC_TIME = "es_ES.UTF-8";
    };

    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gnome pkgs.xdg-desktop-portal-gtk ];
      config.common.default = "gtk";
    };

    nixpkgs.config.allowUnfree = true;

    security.polkit.enable = true;
    systemd.user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };

    # Configure console keymap
    console.keyMap = "es";

    # --- CONFIGURACIÓN DE XSERVER (Base para SDDM) ---
    services.xserver = {
      enable = true;
      xkb = {
        layout = "es";
        variant = "nodeadkeys";
      };
      videoDrivers = [ "nvidia" ];
    };

    # --- OPTIMIZACIÓN NVIDIA + PLYMOUTH ---
    # Esto fuerza a que el driver de NVIDIA cargue antes que el login
    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      open = false; # Cambiar a true si usas una tarjeta serie 20 o superior y prefieres drivers open
      nvidiaSettings = true;
    };

    # --- NETWORKING Y LOCALIZACIÓN ---
    networking.hostName = "desktop";
    networking.networkmanager.enable = true;
    time.timeZone = "Europe/Madrid";
    i18n.defaultLocale = "es_ES.UTF-8";

    # --- USUARIOS ---
    users.users.jano = {
      isNormalUser = true;
      description = "jano";
      extraGroups = [ "networkmanager" "wheel" "video" "audio" ];
    };

    # --- PROGRAMAS Y SYSTEMD ---
    # Evitamos que el terminal se llene de mensajes durante la animación de Plymouth
    boot.consoleLogLevel = 0;
    boot.initrd.verbose = false;

    users.defaultUserShell = pkgs.zsh;
    system.userActivationScripts.zshrc = "touch .zshrc";

    services.pipewire = {
      enable = true;
      alsa.enable = true;
     pulse.enable = true;
    };

    hardware.bluetooth.enable = true;
    services.power-profiles-daemon.enable = true;
    services.upower.enable = true;

    # Help Niri find your hardware
    hardware.graphics.enable = true;

    # Enable Flakes
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    system.stateVersion = "25.11";
  };
}
