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
  # SDDM prefers the last-used session over defaultSession; forget it every
  # boot so a stale Plasma X11 choice can never override Wayland.
  systemd.tmpfiles.rules = [ "r /var/lib/sddm/state.conf" ];
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
    cursorTheme=blank
  '';
  environment.etc."xdg/kwinrc".text = ''
    [Windows]
    BorderlessMaximizedWindows=true
  '';
    # Android-like: a single tap opens files/folders (no double-click).
  environment.etc."xdg/kdeglobals".text = ''
    [KDE]
    SingleClick=true
  '';
  # Kando runs in the background from login so the pie menu opens instantly.
  # Wayland has no app-level global hotkeys: open it with a Plasma shortcut or
  # the "Kando Menu" launcher (kando --menu "<menu name>").
  environment.etc."xdg/autostart/kando.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Kando
    Exec=${pkgs.kando}/bin/kando
    X-GNOME-Autostart-enabled=true
  '';
  # Declarative Kando menus (read-only: edit kando-menus.json, then rebuild).
  home-manager.users.jano.xdg.configFile."kando/menus.json" = {
    source = ./kando-menus.json;
    force = true;
  };

  # Touch gestures via lisgd (auto-detects the touchscreen, skips the pen).
  users.users.jano.extraGroups = [ "input" ];
  systemd.user.services.lisgd = {
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Restart = "on-failure";
      ExecStart = pkgs.writeShellScript "lisgd-start" ''
        for d in /sys/class/input/event*; do
          n=$(cat $d/device/name 2>/dev/null)
          if echo "$n" | grep -qi 'virtual touchscreen' && ! echo "$n" | grep -qiE 'pen|stylus|pad'; then
            dev=/dev/input/$(basename $d); break
          fi
        done
        [ -n "$dev" ] || exit 1
        exec ${pkgs.lisgd}/bin/lisgd -d "$dev" \
          -g "1,RL,R,*,R,${pkgs.kando}/bin/kando --menu 'Tablet'" \
          -g "1,LR,L,*,R,${pkgs.kdePackages.qttools}/bin/qdbus org.kde.kglobalaccel /component/kwin invokeShortcut Overview"
      '';
    };
  };
  home-manager.users.jano.xdg.configFile."kando/menu-themes" = { source = ./kando-themes; recursive = true; };
  environment.sessionVariables.BROWSER = "zen";
  home-manager.users.jano.home.activation.kandoTouch =
    inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      f="$HOME/.config/kando/config.json"
      mkdir -p "$(dirname "$f")"
      [ -f "$f" ] || echo '{}' > "$f"
      ${pkgs.jq}/bin/jq '. * {
        zoomFactor: 1.8,
        centerDeadZone: 80,
        dragThreshold: 25,
        hoverMode: false,
        enableMarkingMode: false,
        enableTurboMode: false,
        ignoreWriteProtectedConfigFiles: true
      }' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    '';
  environment.sessionVariables.XCURSOR_SIZE = "36";
  environment.sessionVariables.XCURSOR_THEME = "blank";
  environment.pathsToLink = [ "/share/icons" ];

  environment.systemPackages = with pkgs; [
    blankCursor
    (writeShellScriptBin "waydroid-setup" ''
      set -e
      sudo waydroid init -f            # vanilla image, no Google apps
      sudo systemctl restart waydroid-container
      waydroid session start &
      sleep 20
      ${pkgs.curl}/bin/curl -L -o /tmp/F-Droid.apk https://f-droid.org/F-Droid.apk
      waydroid app install /tmp/F-Droid.apk
      waydroid show-full-ui &
      echo "In Android: open F-Droid, search 'Aurora Store', install it."
    '')
    (makeDesktopItem {
      name = "google-classroom";
      desktopName = "Google Classroom";
      exec = "zen --new-window https://classroom.google.com";
      icon = "internet-web-browser";
      categories = [ "Education" ];
    })
    (makeDesktopItem {
      name = "kando-menu";
      desktopName = "Kando Menu";
      exec = "${kando}/bin/kando --menu \"Tablet\"";
      icon = "kando";
      categories = [ "Utility" ];
    })
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
    lisgd     # touch gestures
    playerctl
  ];
}
