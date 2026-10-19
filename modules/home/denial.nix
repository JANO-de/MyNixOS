# Declarative Denial settings (Surface only, gated by `denialEnabled` =
# config.programs.denial.enable in ../core/home-manager.nix).
#
# Enforced into ~/.config/denial/settings.json. Denial tolerates partial
# documents: any field omitted here falls back to its built-in default
# (compositor/src/bin/deniald/settings.rs, parse_document). The values below
# are tuned to cut GPU load on the Surface's Intel HD 620 at 2736x1824:
# glass blur/refraction off, opaque panels/cards, reduced animations.
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
  settings = builtins.toJSON {
    version = 28;
    appearance = {
      transparencyMode = "off";
      backdropBlurLevel = "shitty";
      panelOpacity = 1.0;
      cardOpacity = 1.0;
      focusedWindowOpacity = 1.0;
      unfocusedWindowOpacity = 1.0;
      cornerRadiusScale = 0.4;
      focusedWindowBorderEnabled = false;
    };
    animations = {
      durationScale = 0.5;
      windowCloseEffect = "fade";
    };
  };
  settingsFile = pkgs.writeText "denial-settings.json" settings;
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
}
