{ self, inputs, ... }: {
  flake.nixosModules.core = { pkgs, ... }: 
  # --- LET BLOCK STARTS HERE ---
  let
    hunt-sddm-theme = pkgs.stdenv.mkDerivation {
      pname = "sddm-hunt-theme";
      version = "1.0";
      src = pkgs.fetchFromGitHub {
        owner = "MarianArlt";
        repo = "sddm-sugar-candy";
        rev = "v1.2";
        sha256 = "0199cn7sp769n0mqv0mxy7m07vj6shf760f38y6p39sxl60i491s";
      };
      installPhase = ''
        mkdir -p $out/share/sddm/themes/sugar-candy
        cp -r ./* $out/share/sddm/themes/sugar-candy/
        
        # Copy the specific frame for the background
        cp ${../parts/base/plymouth/hunt/media/1920x1080/ezgif-frame-173.png} $out/share/sddm/themes/sugar-candy/Backgrounds/hunt-bg.png
        
        # Overwrite the config file with your specific Hunt settings
        cat <<EOF > $out/share/sddm/themes/sugar-candy/theme.conf
[General]
Background="Backgrounds/hunt-bg.png"
ScreenWidth=1920
ScreenHeight=1080
FormPosition=center
HaveFormBackground=true
PartialBlur=true
MainColor=#cc0000
AccentColor=#cc0000
BackgroundColor=#000000
FullSizeButtons=true
UserPictureEnabled=true
# Setting specific fonts or red text colors here
EOF
      '';
    };
  in
  # --- MODULE BODY STARTS HERE ---
  {
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

    users.users.jano = {
      isNormalUser = true;
      extraGroups = [ "networkmanager" "wheel" "video" "adbuser" "dialout" "libvirtd" ];
      useDefaultShell = true;
      shell = pkgs.zsh;
    };

    users.defaultUserShell = pkgs.zsh;
    system.userActivationScripts.zshrc = "touch .zshrc";

    services.pipewire = {
      enable = true;
      alsa.enable = true;
     pulse.enable = true;
    };

    # Common Networking
    networking.networkmanager.enable = true;

    environment.systemPackages = with pkgs; [
      libsForQt5.qt5.qtgraphicaleffects
      libsForQt5.qt5.qtquickcontrols2
      libsForQt5.qt5.qtsvg
    ];

    # 2. Boot & Plymouth
    boot = {
      plymouth = {
        enable = true;
        theme = "hunt";
        themePackages = [
          (pkgs.stdenv.mkDerivation {
            pname = "hunt-local-theme";
            version = "1.0";
            src = ../parts/base/plymouth/hunt;
            installPhase = ''
              mkdir -p $out/share/plymouth/themes/hunt
              cp -r ./* $out/share/plymouth/themes/hunt/
              substituteInPlace $out/share/plymouth/themes/hunt/hunt.plymouth \
                --replace "/usr/share/plymouth/themes/hunt" "$out/share/plymouth/themes/hunt"
              substituteInPlace $out/share/plymouth/themes/hunt/hunt.script \
                --replace "/media/" "$out/share/plymouth/themes/hunt/media/"
            '';
          })
        ];
      };
      consoleLogLevel = 3;
      initrd.verbose = false;
      kernelParams = [ "quiet" "splash" "udev.log_level=3" "systemd.show_status=auto" ];
      loader.timeout = 3;
      loader.systemd-boot.enable = true;
      loader.efi.canTouchEfiVariables = true;
    };

    # 3. SDDM Configuration
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      # Use the derivation defined in the 'let' block
      theme = "${hunt-sddm-theme}/share/sddm/themes/sugar-candy";
    };
    #services.displayManager.autoLogin.enable = true;
    #services.displayManager.autoLogin.user = "jano";

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
