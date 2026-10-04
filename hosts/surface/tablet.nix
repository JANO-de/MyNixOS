# Plasma 6 (Wayland) tablet session: login screen, on-screen keyboard, pen and
# touch apps. Auto-rotate (iio) and the udev button rules are in hardware.nix.
# Touch Mode: System Settings > Workspace > General Behavior.
{ pkgs, lib, ... }:

{
  # Plasma on Wayland, themed SDDM greeter with an on-screen keyboard so the
  # login screen is not a dead end without the Type Cover. The greeter itself
  # stays on X11, which is the reliable path on this panel.
  modules.desktop = {
    niri.enable = false;
    displayManager = "sddm";
    greeterOsK.enable = true;
  };
  services.displayManager.defaultSession = "plasma";
  services.displayManager.sddm.wayland.enable = false;

  # Electron/Chromium apps (VS Code, browsers) use Wayland natively.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # home/theme.nix sets Qt to gtk3+Kvantum for the niri hosts. Under Plasma that
  # override is what turns System Settings' QML pages white; let Plasma own Qt.
  home-manager.users.jano.qt.enable = lib.mkForce false;

  # Touch-friendly system-wide Plasma defaults (users can still override).
  # Tablet Mode itself is automatic in Plasma 6 once linux-surface reports the
  # Type Cover detach switch.
  environment.etc."xdg/kcminputrc".text = ''
    [Mouse]
    cursorSize=36
  '';
  environment.etc."xdg/kwinrc".text = ''
    [Windows]
    BorderlessMaximizedWindows=true
  '';
  environment.sessionVariables.XCURSOR_SIZE = "36";

  environment.systemPackages = with pkgs; [
    wl-clipboard
    qt6.qtvirtualkeyboard # greeter on-screen keyboard (see modules/desktop/greeter.nix)

    firefox
    kdePackages.okular
    kdePackages.kdeconnect-kde
    xournalpp # pen: PDF annotation
    rnote     # pen: infinite-canvas handwriting
    krita
    anki
    kando     # touch pie-menu launcher
  ]
  # In-session on-screen keyboard (Plasma 6.4+); skipped if this nixpkgs lacks it.
  ++ lib.optional (pkgs.kdePackages ? plasma-keyboard) pkgs.kdePackages.plasma-keyboard;
}
