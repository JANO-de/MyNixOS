# Plasma 6 (Wayland) tablet session: login screen, on-screen keyboard, pen and
# touch apps. Auto-rotate (iio) and the udev button rules are in hardware.nix.
# Touch Mode: System Settings > Workspace > General Behavior.
{ pkgs, lib, inputs, ... }:

let
  # Fully transparent cursor theme: every cursor name Adwaita knows points at
  # one 1x1 transparent image. Plasma Wayland draws a default cursor even with
  # no pointer device; this hides it. Switch to Breeze in System Settings >
  # Cursors when using the Type Cover touchpad.
  blankCursor = pkgs.runCommand "blank-cursor"
    {
      nativeBuildInputs = [ (pkgs.xcursorgen or pkgs.xorg.xcursorgen) pkgs.python3 ];
    }
    ''
      d=$out/share/icons/blank
      mkdir -p $d/cursors && cd $d
      python3 - <<'PY'
      import struct, zlib
      def chunk(t, b):
          c = struct.pack(">I", len(b)) + t + b
          return c + struct.pack(">I", zlib.crc32(t + b) & 0xffffffff)
      png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 6, 0, 0, 0)) \
          + chunk(b"IDAT", zlib.compress(b"\x00\x00\x00\x00\x00")) + chunk(b"IEND", b"")
      open("blank.png", "wb").write(png)
      PY
      echo "1 0 0 blank.png" > cfg
      xcursorgen cfg cursors/blank
      rm blank.png cfg
      for f in $(ls ${pkgs.adwaita-icon-theme}/share/icons/Adwaita/cursors); do
        [ "$f" = blank ] || ln -s blank cursors/$f
      done
      printf '[Icon Theme]\nName=blank\n' > index.theme
    '';
in
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
  # Touch-only login: hide the X cursor (touch still works; the touchpad
  # pointer is invisible at the login screen only).
  services.displayManager.sddm.settings.X11.ServerArguments = "-nolisten tcp -nocursor";

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
    cursorTheme=blank
  '';
  environment.etc."xdg/kwinrc".text = ''
    [Windows]
    BorderlessMaximizedWindows=true
  '';
  environment.sessionVariables.BROWSER = "zen";
  environment.sessionVariables.XCURSOR_SIZE = "36";
  environment.sessionVariables.XCURSOR_THEME = "blank";
  environment.pathsToLink = [ "/share/icons" ];

  environment.systemPackages = with pkgs; [
    blankCursor
    wl-clipboard
    qt6.qtvirtualkeyboard # greeter on-screen keyboard (see modules/desktop/greeter.nix)

    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
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
