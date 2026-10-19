# Declarative Denial settings (Surface only, gated by `denialEnabled` =
# config.programs.denial.enable in ../core/home-manager.nix).
#
# Seeded into ~/.config/denial/settings.json. Denial tolerates partial
# documents: any field omitted here falls back to its built-in default
# (compositor/src/bin/deniald/settings.rs, parse_document). The values below
# are tuned to cut GPU load on the Surface's Intel HD 620 at 2736x1824:
# glass blur/refraction off, opaque panels/cards, reduced animations.
#
# NB: Denial rewrites this file when the user changes settings at runtime
# (it renames a temp file over the symlink). Home Manager restores the
# declarative version on the next activation and backs the edit up as
# settings.json.backup.
{ lib, denialEnabled, ... }:

{
  xdg.configFile."denial/settings.json" = lib.mkIf denialEnabled {
    text = builtins.toJSON {
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
  };
}
