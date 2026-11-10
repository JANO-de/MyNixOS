# Desktop session: the SDDM login screen and the Wayland session basics every host shares.
# Compositor and shell come with the compositor module.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.desktop;

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
  ];

  options.modules.desktop = {
    enable = lib.mkEnableOption "the desktop session (login screen, Wayland session basics)";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      # ---- login screen ------------------------------------------------------
      # X11 greeter on every host: the reliable path (NVIDIA on desktop/laptop,
      # touch on the Surface). The session itself is Wayland.
      services.xserver.enable = true;
      services.displayManager.sddm = {
        enable = true;
        wayland.enable = false;
        extraPackages = with pkgs.kdePackages; [
          qtmultimedia
          qtsvg
          qtvirtualkeyboard
        ];
        theme = "sddm-astronaut-theme";
      };
      # SDDM prefers the last-used session over defaultSession; forget it every
      # boot so a stale choice (e.g. an old Plasma entry) can never win.
      systemd.tmpfiles.rules = lib.optional config.services.displayManager.sddm.enable "r /var/lib/sddm/state.conf";

      # ---- session basics ----------------------------------------------------
      # Electron apps (vscodium, vesktop, claude-desktop...) run natively on Wayland
      environment.sessionVariables.NIXOS_OZONE_WL = "1";
      security.polkit.enable = true;
      xdg.portal.enable = lib.mkDefault true;
      xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ]; # file picker

      programs.kdeconnect.enable = true;
      services.tumbler.enable = true;
      hardware.bluetooth.enable = true;
      services.blueman.enable = true;
      programs.dconf.enable = true;
      programs.dconf.profiles.user.databases = [
        { settings."org/gnome/desktop/interface".icon-theme = "Papirus-Dark"; }
        { settings."org/gnome/desktop/a11y/applications".screen-keyboard-enabled = true; }
      ];
      environment.sessionVariables.QML2_IMPORT_PATH = lib.makeSearchPath "lib/qt-6/qml" [
        pkgs.qt6.qt5compat
        pkgs.qt6.qtmultimedia
        pkgs.qt6.qtpositioning
        pkgs.qt6.qtsvg
        pkgs.kdePackages.kirigami.unwrapped
        pkgs.kdePackages.syntax-highlighting
      ];
      environment.sessionVariables.XDG_DATA_DIRS = [
        "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
        "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
      ];

      # Tools the shell and the keybinds call at runtime
      environment.systemPackages =
        with pkgs;
        [
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
          localsend-cli
          gdk-pixbuf
          librsvg
          bc
          glib
          imagemagick
        ]
        ++ lib.optional config.services.displayManager.sddm.enable astronaut;
    })

  ];
}
