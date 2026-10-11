# =============================================================================
#  NixOS module (wraps home-manager) for the Quickshell Dynamic Island shell.
#  Folder: modules/desktop/shell/dynisland/ — import ./default.nix from your
#  NixOS config. Then rebuild.
#
#  Command:  dynisland {start|stop|restart|dev|settings|log}
#    start/stop/restart  background copy installed by Nix (needs rebuild to update)
#    dev                 runs from the repo, foreground, hot reload + logs
#    settings            toggles the settings window
# =============================================================================
{ pkgs, lib, ... }:
let
  # Tools the shell calls at runtime (service PATH is minimal, so list them)
  runtimeDeps = with pkgs; [
    cava matugen brightnessctl networkmanager curl niri coreutils bash
  ];

  # Icon font copied to a fixed path (works regardless of fontconfig/PATH)
  iconFont = pkgs.runCommand "dynisland-icon-font" { nativeBuildInputs = [ (pkgs.python3.withPackages (p: [ p.fonttools ])) ]; } ''
    mkdir -p $out
    f=$(find ${pkgs.material-symbols} \( -name '*.ttf' -o -name '*.otf' \) -iname '*Outlined*' | head -1)
    [ -n "$f" ] || { echo "Outlined font not found"; exit 1; }
    cp "$f" $out/icons.ttf
    # name -> codepoint map, read from the font's ligature table
    python3 - "$f" $out/icons.json <<'PY'
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
  repoShell = "$HOME/Documents/MyNixOS/modules/desktop/shell/dynisland/shell.qml";

  dynisland = pkgs.writeShellScriptBin "dynisland" ''
    qs=${pkgs.quickshell}/bin/qs
    export DYN_ICON_FONT=${iconFont}/icons.ttf
    export DYN_ICON_MAP=${iconFont}/icons.json
    export QS_ICON_THEME=Papirus-Dark
    export PATH=${lib.makeBinPath runtimeDeps}:$PATH
    case "$1" in
      start)    $qs kill -c dynisland 2>/dev/null; setsid $qs -c dynisland >/dev/null 2>&1 & ;;
      stop)     $qs kill -c dynisland ;;
      restart)  $qs kill -c dynisland 2>/dev/null; sleep 0.5; setsid $qs -c dynisland >/dev/null 2>&1 & ;;
      dev)      $qs kill -c dynisland 2>/dev/null; exec $qs -p "${repoShell}" ;;
      settings) $qs -c dynisland ipc call settings toggle ;;
      log)      $qs log -c dynisland ;;
      *)        echo "usage: dynisland {start|stop|restart|dev|settings|log}" ;;
    esac
  '';
in {
  home-manager.users.jano = {
    home.packages = (with pkgs; [ quickshell material-symbols inter ]) ++ runtimeDeps ++ [ dynisland ];

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
        Environment = [ "DYN_ICON_FONT=${iconFont}/icons.ttf" "DYN_ICON_MAP=${iconFont}/icons.json" "QS_ICON_THEME=Papirus-Dark" "XDG_DATA_DIRS=/run/current-system/sw/share:/etc/profiles/per-user/jano/share:%h/.nix-profile/share" "PATH=${lib.makeBinPath runtimeDeps}:/run/current-system/sw/bin" ];
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
