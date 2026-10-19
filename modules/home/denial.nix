# Declarative Denial settings (Surface only, gated by `denialEnabled` =
# config.programs.denial.enable in ../core/home-manager.nix).
#
# The JSON lives in ./denial-settings.json so the settings app's output can be
# exported straight back into the repo (see `denial-settings-export` below).
# Denial tolerates partial documents: any field omitted here falls back to its
# built-in default (compositor/src/bin/deniald/settings.rs, parse_document).
# The values shipped here are tuned to cut GPU load on the Surface's Intel
# HD 620 at 2736x1824: glass blur/refraction off, opaque panels/cards, reduced
# animations.
#
# NB: this must NOT be an `xdg.configFile` entry. Home Manager materializes
# those as symlinks into /nix/store, and deniald's settings loader refuses
# symlinks (read_settings_file -> symlink_metadata().file_type().is_symlink()
# -> SettingsError::Path). That error propagates out of startup and main()
# calls std::process::abort(), which is the SIGABRT at session start that
# produced the login loop/drkonqi storm. We instead write a regular file with
# an activation hook. This is declarative-authoritative: whenever the on-disk
# file differs from the JSON below (including Denial's own runtime
# normalization, e.g. its added `revision` field), the previous file is saved
# to settings.json.backup and replaced.
{ pkgs, lib, denialEnabled, ... }:

let
  settingsFile = pkgs.writeText "denial-settings.json"
    (builtins.readFile ./denial-settings.json);

  # Run on the Surface after changing something in denial-settings:
  #   denial-settings-export            # print current settings as JSON
  #   denial-settings-export PATH       # write them to PATH (e.g. a repo
  #                                     # checkout available on this machine)
  # Then copy the result over modules/home/denial-settings.json and rebuild.
  denialSettingsExport = pkgs.writeShellApplication {
    name = "denial-settings-export";
    runtimeInputs = [ pkgs.coreutils pkgs.jq ];
    text = ''
      src="''${XDG_CONFIG_HOME:-$HOME/.config}/denial/settings.json"
      if [ ! -f "$src" ]; then
        echo "denial-settings-export: no settings file at $src" >&2
        exit 1
      fi
      if [ "$#" -eq 0 ]; then
        jq . "$src"
        exit 0
      fi
      dest="$1"
      mkdir -p "$(dirname "$dest")"
      tmp="$(mktemp "$dest.XXXXXX")"
      jq . "$src" > "$tmp"
      mv "$tmp" "$dest"
      echo "denial-settings-export: wrote $dest" >&2
    '';
  };
in
{
  home.activation.denialSettings = lib.mkIf denialEnabled (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settingsPath="$HOME/.config/denial/settings.json"
    sourcePath=${settingsFile}
    if [ -L "$settingsPath" ]; then
      run rm -f "$settingsPath"
    fi
    if ! cmp -s "$sourcePath" "$settingsPath" 2>/dev/null; then
      if [ -e "$settingsPath" ]; then
        run cp -f "$settingsPath" "$settingsPath.backup"
      fi
      run mkdir -p "$HOME/.config/denial"
      run chmod 700 "$HOME/.config/denial"
      run install -m 600 "$sourcePath" "$settingsPath"
    fi
  '');

  home.packages = lib.mkIf denialEnabled [ denialSettingsExport ];

  # Declarative display scale. A store symlink here is treated by Denial's
  # launcher as declarative input (copied to ~/.local/state/denial/outputs.conf).
  # Scale 2 (not 1.5): most clients ignore wp_fractional_scale and render blurry/cropped.
  xdg.configFile."denial/outputs.conf" = lib.mkIf denialEnabled {
    text = ''
      eDP-1=0,0
      mode=eDP-1,2736,1824,59959
      scale=eDP-1,2
      primary=eDP-1
    '';
  };

  # gtk.enable owns ~/.gtkrc-2.0; stop stale .backup files from blocking activation.
  gtk.gtk2.force = lib.mkIf denialEnabled true;
}
