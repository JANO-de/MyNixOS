# Desktop session: which compositor runs (mango | niri | hyprland), which shell sits on top
# (dynisland | chronos), the SDDM login screen (optional on-screen keyboard for
# touch-only devices) and the Wayland session basics every host shares.
#
#   desktop, laptop:  session = "mango"  shell = "dynisland"   (defaults)
#   halos1:           session = "niri"   shell = "chronos"
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.desktop;
  theme = "share/sddm/themes/catppuccin-mocha-mauve";
  oskTheme = import ./sddm-osk.nix { inherit (pkgs) lib stdenvNoCC catppuccin-sddm; };

  # Greeter theme for hosts without the on-screen keyboard (desktop, laptop).
  # Change embeddedTheme (astronaut, black_hole, cyberpunk, hyprland_kath,
  # japanese_aesthetic, pixel_sakura, purple_leaves...) or add themeConfig keys.
  astronaut = pkgs.sddm-astronaut.override {
    embeddedTheme = "purple_leaves";
    themeConfig.HeaderText = "Welcome";
  };
in
{
  imports = [
    ./mango.nix
    ./niri.nix
    ./hyprland.nix
    ./hyprland-touch.nix
    ./shell/dynisland
    ./shell/chronos.nix
    ./shell/halo.nix
    ./greeter.nix
    ./splash.nix
    ./droidloom.nix
  ];

  options.modules.desktop = {
    session = lib.mkOption {
      type = lib.types.enum [ "mango" "niri" "hyprland" ];
      default = "mango";
      description = "Compositor started by the login screen. 'niri' is the chronos fork; 'hyprland' runs through UWSM (see hyprland.nix).";
    };
    shell = lib.mkOption {
      type = lib.types.enum [ "dynisland" "chronos" "halo" ];
      default = "dynisland";
      description = "Quickshell shell (island, dock, launcher, lock) autostarted in the session.";
    };
    hyprlandMode = lib.mkOption {
      type = lib.types.enum [ "tablet" "desktop" ];
      default = "desktop";
      description = "Hyprland mode at first login of a boot (tablet = touch UI, desktop = pointer UI). Written to /etc/hypr/default-mode.";
    };
    greeterOsk.enable = lib.mkEnableOption ''
      an on-screen keyboard in the SDDM greeter (Qt virtual keyboard), so a
      touch-only device can be logged into
    '';
  };

  config = lib.mkMerge [
    {
      # ---- login screen ------------------------------------------------------
      # X11 greeter on every host: the reliable path (NVIDIA on desktop/laptop,
      # touch on the Surface). The session itself is Wayland.
      services.xserver.enable = true;
      services.displayManager.sddm = {
        enable = true;
        wayland.enable = false;
        extraPackages = with pkgs.kdePackages; [ qtmultimedia qtsvg qtvirtualkeyboard ];
        theme = if cfg.greeterOsk.enable
          then "${oskTheme}/${theme}"
          else "sddm-astronaut-theme";
      };
      services.displayManager.defaultSession =
        if cfg.session == "hyprland" then "hyprland-uwsm" else cfg.session;
      # SDDM prefers the last-used session over defaultSession; forget it every
      # boot so a stale choice (e.g. an old Plasma/niri entry) can never win.
      systemd.tmpfiles.rules = lib.optional config.services.displayManager.sddm.enable "r /var/lib/sddm/state.conf";

      # ---- session basics ----------------------------------------------------
      # Electron apps (vscodium, vesktop, claude-desktop...) run natively on Wayland
      environment.sessionVariables.NIXOS_OZONE_WL = "1";
      security.polkit.enable = true;

      programs.dconf.enable = true;
      programs.dconf.profiles.user.databases = [
        { settings."org/gnome/desktop/interface".icon-theme = "Papirus-Dark"; }
        { settings."org/gnome/desktop/a11y/applications".screen-keyboard-enabled = true; }
      ];
      environment.sessionVariables.XDG_DATA_DIRS = [
        "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
        "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
      ];

      # Tools the shell and the keybinds call at runtime
      environment.systemPackages = with pkgs; [
        wl-clipboard
        cliphist
        libnotify
        grim
        slurp
        wf-recorder
        brightnessctl
        playerctl
        xdg-utils
        adwaita-icon-theme # cursor theme
        pavucontrol
      ] ++ lib.optional (!cfg.greeterOsk.enable && config.services.displayManager.sddm.enable) astronaut;
    }

    (lib.mkIf cfg.greeterOsk.enable {
      services.displayManager.sddm.settings.General = {
        # SDDM's documented knob for tablets: the greeter uses the Qt virtual
        # keyboard as its input method.
        InputMethod = "qtvirtualkeyboard";
        # The theme's `import QtQuick.VirtualKeyboard` needs the QML modules and
        # the input-context plugin on the greeter's paths (see sddm-osk.nix for
        # the theme that actually draws the keyboard).
        GreeterEnvironment = "QT_IM_MODULE=qtvirtualkeyboard,QML2_IMPORT_PATH="
          + lib.makeSearchPath "lib/qt-6/qml" [ pkgs.qt6.qtdeclarative pkgs.qt6.qtvirtualkeyboard ]
          + ",QT_PLUGIN_PATH="
          + lib.makeSearchPath "lib/qt-6/plugins" [
            pkgs.qt6.qtvirtualkeyboard
            pkgs.qt6.qtbase
            pkgs.qt6.qtsvg
            pkgs.qt6.qtdeclarative
          ];
      };
      environment.systemPackages = [ pkgs.qt6.qtvirtualkeyboard ];
    })
  ];
}
