{ self, inputs, ... }: {
  flake.nixosModules.core = { pkgs, ...}: {
    imports = [
      self.nixosModules.basicApps
      self.nixosModules.services
      self.nixosModules.basicfonts
    ];

    # Standard System Settings
    time.timeZone = "Europe/Madrid"; # Change to your zone

    # Set the system-wide language
    i18n.defaultLocale = "es_ES.UTF-8";

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
      extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
      config.common.default = "*";
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

    services.xserver.xkb = {
      layout = "es";
      variant = "nodeadkeys";
    };

    # Configure console keymap
    console.keyMap = "es";

    # Common Networking
    networking.networkmanager.enable = true;

    # Bootloader (Standard for UEFI systems)
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
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
