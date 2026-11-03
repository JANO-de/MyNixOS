# Office suite.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.programs.office;
in
{
  options.modules.programs.office.enable = lib.mkEnableOption "the office suite (LibreOffice)";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      libreoffice-qt
      # inputs.classwork.packages.${system}.default
    ];
  };
}
