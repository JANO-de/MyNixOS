{ config, lib, pkgs, ... }:

# Which login screen (greeter) runs.
#
# The two greeters in nixpkgs are not interchangeable: GDM is the GNOME one and
# is what a GNOME session expects, SDDM is the one that themes nicely (the same
# catppuccin theme the Plasma desktop already uses here). Owning the choice in
# one place is also what keeps the two from being enabled at the same time,
# which systemd would refuse to start.
#
# Hosts with Plasma keep SDDM regardless, since that is what the Plasma session
# is built against; everything else follows the option.
#
# greeterOsK additionally teaches SDDM's own input-method hookup to load the Qt
# virtual keyboard. GDM has no such knob (its caribou keyboard is gone), so the
# option only does anything for SDDM.
let
  cfg = config.modules.desktop;
  sddmWanted = cfg.displayManager == "sddm" || cfg.plasma.enable;
  oskWanted = sddmWanted && cfg.greeterOsK.enable;
in
{
  config = {
    services.displayManager.sddm = lib.mkMerge [
      (lib.mkIf sddmWanted {
        enable = true;
        theme =
          if oskWanted then
            "${import ../../overlays/sddm-catppuccin-osk.nix {
              inherit (pkgs) lib stdenvNoCC catppuccin-sddm;
            }}/share/sddm/themes/catppuccin-mocha-mauve"
          else
            "${pkgs.catppuccin-sddm}/share/sddm/themes/catppuccin-mocha-mauve";
      })

      (lib.mkIf oskWanted {
        # The greeter's .so is not the problem: nixpkgs' sddm wrapper already
        # carries the virtual keyboard in the greeter's QT_PLUGIN_PATH (check the
        # wrapper's own binary), and the plugin really does load there. What is
        # missing is a theme that draws it, which is what the patched theme above
        # is for.
        settings.General = {
          # SDDM's documented knob for tablets: makes the greeter use the Qt
          # virtual keyboard as its input method, so the InputPanel the theme
          # instantiates is backed by a working input context.
          InputMethod = "qtvirtualkeyboard";

          # The theme's `import QtQuick.VirtualKeyboard` still needs the QML
          # modules on the import path. The wrapper only passes Qt's own modules
          # through NIXPKGS_QT6_QML_IMPORT_PATH, which is not a variable the QML
          # engine reads, so the keyboard's modules have to be named here.
          # GreeterEnvironment is a comma-separated KEY=value list in [General].
          GreeterEnvironment = "QML2_IMPORT_PATH="
            + lib.makeSearchPath "lib/qt-6/qml" [
              pkgs.qt6.qtdeclarative
              pkgs.qt6.qtvirtualkeyboard
            ];
        };
      })
    ];
  };
}
