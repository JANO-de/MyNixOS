# ii (ii-p3drovfx) shell module. Opt-in: modules.desktop.shell = "ii".
{ config, lib, pkgs, ... }:
let
  cfg = config.modules.desktop.ii;
in
{
  options.modules.desktop.ii.enable = lib.mkEnableOption "ii (ii-p3drovfx) Quickshell shell on Hyprland";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.ii pkgs.matugen pkgs.quickshell pkgs.qt6.qt5compat pkgs.qt6.qtmultimedia pkgs.qt6.qtpositioning pkgs.qt6.qtsvg pkgs.kdePackages.kirigami.unwrapped pkgs.kdePackages.syntax-highlighting ];

    home-manager.users.jano.xdg.configFile."quickshell/ii".source =
      "${pkgs.ii}/share/quickshell/ii";

    home-manager.users.jano.systemd.user.services.ii = {
      Unit = {
        Description = "ii shell (Quickshell)";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.quickshell}/bin/qs -c ii";
        Restart = "on-failure";
        Environment = [
          "QS_ICON_THEME=Papirus-Dark"
          "NIXPKGS_QT6_QML_IMPORT_PATH=${pkgs.qt6.qt5compat}/lib/qt-6/qml:${pkgs.qt6.qtmultimedia}/lib/qt-6/qml:${pkgs.qt6.qtpositioning}/lib/qt-6/qml:${pkgs.qt6.qtsvg}/lib/qt-6/qml:${pkgs.kdePackages.kirigami.unwrapped}/lib/qt-6/qml:${pkgs.kdePackages.syntax-highlighting}/lib/qt-6/qml"
          "XDG_DATA_DIRS=/run/current-system/sw/share:/etc/profiles/per-user/jano/share:%h/.nix-profile/share"
          "PATH=/run/wrappers/bin:/etc/profiles/per-user/jano/bin:%h/.nix-profile/bin:/run/current-system/sw/bin"
        ];
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
