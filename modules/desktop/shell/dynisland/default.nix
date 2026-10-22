# =============================================================================
#  NixOS module (wraps home-manager) for the Quickshell Dynamic Island shell.
#  Active when modules.desktop.shell = "dynisland" (desktop, laptop).
#
#  Command:  dynisland {start|stop|restart|dev|settings|log}
#    start/stop/restart  background copy installed by Nix (needs rebuild to update)
#    dev                 runs from the repo, foreground, hot reload + logs
#    settings            toggles the settings window
# =============================================================================
{ config, pkgs, lib, inputs, ... }:
let
  cfg = config.modules.desktop;
  # window/monitor IPC the shell talks to: mmsg on mango, niri msg on niri (see services/Wm.qml)
  wmPackage =
    if cfg.session == "mango" then
      config.programs.mango.package
    else if cfg.session == "hyprland" then
      config.programs.hyprland.package
    else
      inputs.chronos.packages.${pkgs.stdenv.hostPlatform.system}.niri;
  # Tools the shell calls at runtime (service PATH is minimal, so list them)
  runtimeDeps = with pkgs; [
    cava
    matugen
    brightnessctl
    networkmanager
    curl
    wmPackage
    coreutils
    bash
    vdirsyncer
    findutils
    libnotify
    wl-clipboard
    hyprpicker
    gammastep
    wf-recorder
    power-profiles-daemon
    xdg-utils
    tailscale
    openrgb
  ];

  # Icon font copied to a fixed path (works regardless of fontconfig/PATH)
  iconFont =
    pkgs.runCommand "dynisland-icon-font"
      { nativeBuildInputs = [ (pkgs.python3.withPackages (p: [ p.fonttools ])) ]; }
      ''
            mkdir -p $out
            f=$(find ${pkgs.material-symbols} \( -name '*.ttf' -o -name '*.otf' \) -iname '*Rounded*' | head -1)   # Rounded = smoother glyphs
            [ -n "$f" ] || f=$(find ${pkgs.material-symbols} \( -name '*.ttf' -o -name '*.otf' \) -iname '*Outlined*' | head -1)
            [ -n "$f" ] || { echo "Outlined font not found"; exit 1; }
            cp "$f" $out/icons.ttf
            chmod u+w $out/icons.ttf
            # Rename the family to a unique name. Otherwise Qt resolves
            # "Material Symbols Outlined" to some OTHER installed copy (other version/
            # cmap) and draws wrong glyphs.
            python3 - $out/icons.ttf <<'PY'
        import sys
        from fontTools.ttLib import TTFont
        t = TTFont(sys.argv[1])
        for r in t["name"].names:
            if r.nameID in (1, 16): r.string = "DynIcons"
            elif r.nameID in (4, 6): r.string = "DynIcons-Regular"
            elif r.nameID in (2, 17): r.string = "Regular"
        t.save(sys.argv[1])
        PY
            # name -> codepoint map, read from the font's ligature table
            python3 - $out/icons.ttf $out/icons.json <<'PY'
        import sys, json
        from fontTools.ttLib import TTFont
        t = TTFont(sys.argv[1])
        cmap = t.getBestCmap()
        g2c = {}
        for c, g in cmap.items():
            g2c.setdefault(g, c)
        ch = {g: chr(c) for c, g in cmap.items() if c < 0x80}
        out = {}
        for lk in t["GSUB"].table.LookupList.Lookup:
            for st in lk.SubTable:
                st = getattr(st, "ExtSubTable", st)
                if not hasattr(st, "ligatures"):
                    continue
                for first, ligs in st.ligatures.items():
                    for l in ligs:
                        try:
                            name = "".join(ch[c] for c in [first] + list(l.Component))
                        except KeyError:
                            continue
                        cp = g2c.get(l.LigGlyph)
                        if cp is not None and cp >= 0xE000:
                            out.setdefault(name, chr(cp))
        assert len(out) > 1000, len(out)
        json.dump(out, open(sys.argv[2], "w"))
        PY
      '';

  # Repo path used by `dynisland dev`
  repoShell = "$HOME/Proyectos/MyNixOS/modules/desktop/shell/dynisland/shell.qml";

  dynisland = pkgs.writeShellScriptBin "dynisland" ''
    qs=${pkgs.quickshell}/bin/qs
    export DYN_ICON_FONT=${iconFont}/icons.ttf
    export DYN_ICON_MAP=${iconFont}/icons.json
    export QS_ICON_THEME=Papirus-Dark
    export PATH=${lib.makeBinPath runtimeDeps}:$PATH
    # `start`/`restart` run the REPO copy detached (always your latest files, no rebuild needed).
    # `stable` runs the Nix-installed copy instead. `ipc` talks to whichever is running.
    case "$1" in
      start|restart) $qs kill -c dynisland 2>/dev/null; $qs kill -p "${repoShell}" 2>/dev/null; sleep 0.5
                     setsid $qs -p "${repoShell}" >/dev/null 2>&1 & ;;
      stable)   $qs kill -p "${repoShell}" 2>/dev/null; $qs kill -c dynisland 2>/dev/null; sleep 0.5
                setsid $qs -c dynisland >/dev/null 2>&1 & ;;
      stop)     $qs kill -p "${repoShell}" 2>/dev/null; $qs kill -c dynisland 2>/dev/null ;;
      dev)      $qs kill -c dynisland 2>/dev/null; $qs kill -p "${repoShell}" 2>/dev/null; exec $qs -p "${repoShell}" ;;
      ipc)      shift; $qs -p "${repoShell}" ipc call "$@" 2>/dev/null || $qs -c dynisland ipc call "$@" ;;
      settings) "$0" ipc settings toggle ;;
      launcher) "$0" ipc launcher toggle ;;
      server)   "$0" ipc server toggle ;;
      log)      $qs log -p "${repoShell}" 2>/dev/null || $qs log -c dynisland ;;
      *)        echo "usage: dynisland {start|restart|stable|stop|dev|ipc <target> <fn>|settings|launcher|log}" ;;
    esac
  '';
in
{
  config = lib.mkIf (cfg.shell == "dynisland") {
  # ---- Server mode, system side (UNTESTED) -------------------------------------
  # Tailscale daemon idles disconnected; the shell runs `tailscale up/down` with Server mode.
  # --operator lets user jano run tailscale without sudo.
  services.tailscale = {
    enable = true;
    openFirewall = true; # UDP 41641: direct connections (relays work without it)
    extraSetFlags = [ "--operator=jano" ];
  };
  # Power profiles (Sys.cyclePowerProfile -> powerprofilesctl)
  services.power-profiles-daemon.enable = lib.mkDefault true;
  # OpenRGB: no daemon, the shell just calls the CLI (needs i2c for motherboard/RAM LEDs)
  hardware.i2c.enable = true;
  services.udev.packages = [ pkgs.openrgb ];
  environment.systemPackages = [ pkgs.openrgb ];
  users.users.jano.extraGroups = [ "i2c" ];
  # let jano start llama-cpp.service from the shell without a password prompt
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          action.lookup("unit") == "llama-cpp.service" &&
          subject.user == "jano") { return polkit.Result.YES; }
    });
  '';

  home-manager.users.jano = {
    home.packages =
      (with pkgs; [
        quickshell
        material-symbols
        inter
        nixos-icons
      ])
      ++ runtimeDeps
      ++ [ dynisland ];

    # QML tree lives in ~/.config/quickshell/dynisland (qs -c dynisland)
    xdg.configFile."quickshell/dynisland".source = ./.;
    fonts.fontconfig.enable = true;

    systemd.user.services.dynisland = {
      Unit = {
        Description = "Dynamic Island shell (Quickshell)";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.quickshell}/bin/qs -c dynisland";
        Restart = "on-failure";
        Environment = [
          "DYN_ICON_FONT=${iconFont}/icons.ttf"
          "DYN_ICON_MAP=${iconFont}/icons.json"
          "QS_ICON_THEME=Papirus-Dark"
          "XDG_DATA_DIRS=/run/current-system/sw/share:/etc/profiles/per-user/jano/share:%h/.nix-profile/share"
          "PATH=${lib.makeBinPath runtimeDeps}:/run/wrappers/bin:/etc/profiles/per-user/jano/bin:%h/.nix-profile/bin:/run/current-system/sw/bin"
        ];
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
  };
}
