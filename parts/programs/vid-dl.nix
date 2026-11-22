# vid-dl program module (programs.vid-dl.enable): portable PyInstaller video downloader.
_: {
  flake.nixosModules.vid-dl =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.vid-dl;
    in
    {
      options.programs.vid-dl = {
        enable = lib.mkEnableOption "vid-dl, video downloader";
        package = lib.mkPackageOption pkgs "vid-dl" { };
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ cfg.package ];
      };
    };
}
