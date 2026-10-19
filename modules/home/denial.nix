# Declarative Denial settings (Surface only, gated by `denialEnabled` =
# config.programs.denial.enable in ../core/home-manager.nix).
#
# Seeded into ~/.config/denial/settings.json. Denial tolerates partial
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
# produced the login loop/drkonqi storm. We instead copy a regular file in
# place via an activation hook. Denial rewrites this file at runtime, so we
# only (re)place it when it is missing or still a store symlink; a real file
# the user has since edited is left untouched.
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
    if [ ! -e "$settingsPath" ] || [ -L "$settingsPath" ]; then
      run mkdir -p "$HOME/.config/denial"
      run chmod 700 "$HOME/.config/denial"
      run rm -f "$settingsPath"
      run install -m 600 ${settingsFile} "$settingsPath"
    fi
  '');
}
