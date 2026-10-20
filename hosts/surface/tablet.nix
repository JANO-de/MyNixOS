# Plasma 6 (Wayland) tablet session: login screen, on-screen keyboard and a
# hidden cursor so a touch-only Surface can be logged into and used. Auto-rotate
# (iio) and the udev button rules live in hardware.nix.
{ pkgs, inputs, ... }:

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
    niri.enable = true;
    displayManager = "sddm";
    greeterOsK.enable = true;
  };
  services.displayManager.defaultSession = "niri";
  # SDDM prefers the last-used session over defaultSession; forget it every
  # boot so a stale Plasma X11 choice can never override Wayland.
  systemd.tmpfiles.rules = [ "r /var/lib/sddm/state.conf" ];

  # SDDM X11 touch fix (greeter OSK settings live in modules/desktop/greeter.nix;
  # do not redefine settings.General here, it conflicts).
  services.xserver.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = false;
  };

  # Electron/Chromium apps use Wayland natively.
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    XCURSOR_SIZE = "36";
    XCURSOR_THEME = "blank";
    # Touch-first tablet: default to desktop shell; mobile can be toggled from shade if needed.
      DENIAL_SHELL_PROFILE = "mobile";
      DENIAL_FORCE_TOUCH_GESTURES = "1";
  };
  # Link the blank cursor theme so XCURSOR_THEME resolves.
  environment.pathsToLink = [ "/share/icons" ];

  environment.systemPackages = with pkgs; [
    blankCursor
    wl-clipboard
    qt6.qtvirtualkeyboard # greeter on-screen keyboard (see modules/desktop/greeter.nix)
  ];
}
