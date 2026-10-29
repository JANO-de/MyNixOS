# ii (ii-p3drovfx) shell module. Opt-in: modules.desktop.shell = "ii".
#
# Config location:
#  - modules.desktop.dotfiles.enable = false: seeded once into ~/.config (old behaviour).
#  - modules.desktop.dotfiles.enable = true : seeded once into <repo>/dotfiles/<host>/ (see dotfiles.nix),
#    which ~/.config/* then symlinks to, so ii/Hyprland/hyprmon write into your flake repo.
# Seeding never overwrites existing files.
{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.modules.desktop.ii;
  hmDag = inputs.home-manager.lib.hm.dag;

  dotsEnable = config.modules.desktop.dotfiles.enable or false;
  dotsQs = config.modules.desktop.dotfiles.quickshell or false;
  dotsDir = config.modules.desktop.dotfiles.dir or ""; # <repo>/dotfiles/<host>
  base = if dotsEnable then dotsDir else "$HOME/.config";
  qsDir = if dotsEnable && dotsQs then "${dotsDir}/quickshell-ii" else "$HOME/.config/quickshell/ii";
  hyprDir = "${base}/hypr";
  matugenDir = "${base}/matugen";

  iiPython = pkgs.python3.withPackages (ps: [ ps.pygobject3 ps.click ps.loguru ps.tqdm ps.pillow ps.materialyoucolor ps.material-color-utilities ps.opencv4 ps.numpy ps.dbus-python ps.evdev ps.psutil ps.requests ps.scipy ]);
  iiVenv = pkgs.runCommand "ii-venv" {} ''
    mkdir -p $out/bin
    ln -s ${iiPython}/bin/python3 $out/bin/python
    ln -s ${iiPython}/bin/python3 $out/bin/python3
    printf '%s\n' '# dummy activate' > $out/bin/activate
  '';
in
{
  options.modules.desktop.ii.enable = lib.mkEnableOption "ii (ii-p3drovfx) Quickshell shell on Hyprland";

  config = lib.mkIf cfg.enable {
    hardware.i2c.enable = true;
    systemd.tmpfiles.rules = [ "L+ /usr/bin/python3 - - - - ${iiPython}/bin/python3" ];
    services.power-profiles-daemon.enable = lib.mkDefault true;
    services.geoclue2.enable = lib.mkDefault true;
    services.upower.enable = lib.mkDefault true;
    users.users.jano.extraGroups = [ "i2c" ];
    environment.systemPackages = [ pkgs.ii pkgs.matugen pkgs.quickshell pkgs.hyprmon pkgs.qt6.qt5compat pkgs.qt6.qtmultimedia pkgs.qt6.qtpositioning pkgs.qt6.qtsvg pkgs.kdePackages.kirigami.unwrapped pkgs.kdePackages.syntax-highlighting pkgs.bc pkgs.coreutils pkgs.curl pkgs.wget pkgs.ripgrep pkgs.jq pkgs.xdg-user-dirs pkgs.rsync pkgs.eza pkgs.fish pkgs.starship pkgs.kitty pkgs.hyprsunset pkgs.hyprshot pkgs.swappy pkgs.tesseract pkgs.wf-recorder pkgs.upower pkgs.wtype pkgs.ydotool pkgs.fuzzel pkgs.hypridle pkgs.hyprlock pkgs.hyprpicker pkgs.translate-shell pkgs.wlogout pkgs.libqalculate pkgs.cava pkgs.pavucontrol pkgs.wireplumber pkgs.pipewire pkgs.ddcutil pkgs.geoclue2 pkgs.networkmanager pkgs.kdePackages.plasma-nm pkgs.kdePackages.dolphin
pkgs.kdePackages.systemsettings pkgs.kdePackages.xdg-desktop-portal-kde pkgs.xdg-desktop-portal-gtk pkgs.wl-clipboard pkgs.slurp pkgs.brightnessctl pkgs.playerctl pkgs.cliphist
      # --- added by deps audit (runtime tools ii calls) ---
      pkgs.pulseaudio # pactl (pipewire does not ship it)
      pkgs.bluez pkgs.blueman pkgs.libnotify pkgs.glib pkgs.gtk3 pkgs.gjs
      pkgs.imagemagick pkgs.ffmpeg pkgs.yt-dlp pkgs.grim pkgs.hyprshade
      pkgs.git pkgs.file pkgs.fontconfig pkgs.procps pkgs.psmisc pkgs.util-linux pkgs.xdg-utils
      pkgs.jetbrains-mono
      # Rust helper build (see iiRustHelpers)
      pkgs.cargo pkgs.rustc pkgs.gcc ];

    # NOTE: nixpkgs' hyprland / xdg-desktop-portal-hyprland were removed from the list above on
    # purpose: the session uses the flake's Hyprland (hyprland.nix), and hyprctl + the portal must
    # match the running compositor version.

    home-manager.users.jano.home.activation.iiQuickshellConfig = hmDag.entryAfter [ "writeBoundary" ] ''
      qs="${qsDir}"
      run mkdir -p "$(dirname "$qs")"
      if [ -L "$qs" ] || [ ! -d "$qs" ]; then
        run rm -rf "$qs"
        run cp -r ${pkgs.ii}/share/quickshell/ii "$qs"
        run chmod -R u+w "$qs"
      fi
      # Cap parallel thumbnail jobs (upstream starts one background job per file: OOM with big folders)
      thumb="$qs/scripts/thumbnails/generate-thumbnails-magick.sh"
      if [ -f "$thumb" ] && ! ${pkgs.gnugrep}/bin/grep -q 'jobs -rp' "$thumb"; then
        run ${pkgs.gnused}/bin/sed -i '/generate_thumbnail "\$f" &/a while (( $(jobs -rp | wc -l) >= 4 )); do wait -n || true; done' "$thumb"
      fi
      # Make 'Restart Shell' buttons actually restart the systemd service
      run ${pkgs.gnused}/bin/sed -i 's#qs kill -c ii && qs -c ii &#systemctl --user restart ii#g' \
        "$qs/modules/settings/configs/ColorsThemesConfig.qml" \
        "$qs/modules/settings/configs/PresetsConfig.qml" 2>/dev/null || true
    '';

    # ii ships 7 Rust helpers as source only (app_stats, osk_autoshow, touch_gestures,
    # workspace_arranger, workspace_profile_manager, sni_watcher, health_watch).
    # Build the missing ones with upstream's own script. Needs network (crates.io).
    home-manager.users.jano.home.activation.iiRustHelpers = hmDag.entryAfter [ "iiQuickshellConfig" ] ''
      rh="${qsDir}/scripts/rust-helpers.sh"
      if [ -x "$rh" ]; then
        export PATH="${lib.makeBinPath [ pkgs.cargo pkgs.rustc pkgs.gcc pkgs.coreutils pkgs.findutils pkgs.gnugrep pkgs.gnused ]}:$PATH"
        missing="$("$rh" status 2>/dev/null | ${pkgs.gawk}/bin/awk '$2=="missing"||$2=="stale"{print $1}')"
        if [ -n "$missing" ]; then
          # shellcheck disable=SC2086
          run "$rh" build $missing || echo "ii: rust helper build failed (offline?); rerun: $rh build" >&2
        fi
      fi
    '';

    home-manager.users.jano.home.activation.iiMatugenConfig = hmDag.entryAfter [ "writeBoundary" ] ''
      mg="${matugenDir}"
      run mkdir -p "$mg"
      if [ ! -f "$mg/config.toml" ]; then
        run cp -r ${pkgs.ii}/share/matugen/ii/. "$mg/"
        run chmod -R u+w "$mg"
      fi
      # Make gtk css outputs mutable (home-manager symlinks them read-only)
      for f in "$HOME/.config/gtk-3.0/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"; do
        if [ -L "$f" ]; then run rm -f "$f"; run touch "$f"; run chmod u+w "$f"; fi
        if [ ! -e "$f" ]; then run mkdir -p "$(dirname "$f")"; run touch "$f"; run chmod u+w "$f"; fi
      done
    '';

    home-manager.users.jano.home.activation.iiHyprConfig = hmDag.entryAfter [ "writeBoundary" ] ''
      hd="${hyprDir}"
      run mkdir -p "$hd"
      if [ -L "$hd/hyprland.lua" ]; then
        run rm -f "$hd/hyprland.lua"
      fi
      if [ ! -e "$hd/hyprland.lua" ]; then
        run cp ${pkgs.ii}/share/hypr/ii/hyprland.lua "$hd/hyprland.lua"
      fi
      if [ ! -d "$hd/hyprland" ]; then
        run cp -r ${pkgs.ii}/share/hypr/ii/hyprland "$hd/hyprland"
      fi
      run chmod -R u+w "$hd"
    '';

    # config-autobackup was removed: it copied ~/.config/{hypr,quickshell/ii,illogical-impulse,hyprmon}
    # on every change with no pruning (105 GB in ~/.config-backups). With the dotfiles module the
    # configs live in the git repo instead.

    home-manager.users.jano.systemd.user.services.ii = {
      Unit = {
        Description = "ii shell (Quickshell)";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.quickshell}/bin/qs -c ii";
        Restart = "always";
        RestartSec = "5";
        # Keep ii from taking the whole session down: OOM kills stay inside this unit.
        MemoryHigh = "3G";
        MemoryMax = "4G";
        TasksMax = 1500;
        Environment = [
          "TERMINAL=alacritty"
          "HYPRLAND_CONFIG=/home/jano/.config/hypr/hyprland.lua"
          "QT_SCALE_FACTOR=1"
          "QS_ICON_THEME=Papirus-Dark"
          "NIXPKGS_QT6_QML_IMPORT_PATH=${pkgs.qt6.qt5compat}/lib/qt-6/qml:${pkgs.qt6.qtmultimedia}/lib/qt-6/qml:${pkgs.qt6.qtpositioning}/lib/qt-6/qml:${pkgs.qt6.qtsvg}/lib/qt-6/qml:${pkgs.kdePackages.kirigami.unwrapped}/lib/qt-6/qml:${pkgs.kdePackages.syntax-highlighting}/lib/qt-6/qml"
          "XDG_DATA_DIRS=/run/current-system/sw/share:/etc/profiles/per-user/jano/share:%h/.nix-profile/share"
          "PATH=${iiPython}/bin:/run/wrappers/bin:/etc/profiles/per-user/jano/bin:%h/.nix-profile/bin:/run/current-system/sw/bin"
          "ILLOGICAL_IMPULSE_VIRTUAL_ENV=${iiVenv}"
          # ImageMagick limits (thumbnail generation)
          "MAGICK_THREAD_LIMIT=1"
          "MAGICK_MEMORY_LIMIT=256MiB"
          "MAGICK_MAP_LIMIT=512MiB"
          # thumbgen.py runs without the thumbgen-venv.sh wrapper: give it GI + schemas
          "GI_TYPELIB_PATH=${pkgs.gnome-desktop}/lib/girepository-1.0:${pkgs.gtk3}/lib/girepository-1.0:${pkgs.gdk-pixbuf}/lib/girepository-1.0:${pkgs.glib.out}/lib/girepository-1.0"
          "GSETTINGS_SCHEMA_DIR=${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas"
        ];
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
