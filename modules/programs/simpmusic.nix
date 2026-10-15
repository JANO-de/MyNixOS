# SimpMusic — FOSS YouTube Music desktop client.
#
# The package ships its own share/applications/simpmusic.desktop, so adding it to
# environment.systemPackages is all the app drawer needs. libmpv.so.2 comes from
# the nix store, where dlopen() does not search, hence the explicit env var.
{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.modules.programs.simpmusic;
  system = pkgs.stdenv.hostPlatform.system;
in
{
  options.modules.programs.simpmusic.enable = lib.mkEnableOption "SimpMusic desktop client";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      inputs.simpmusic.packages.${system}.default
    ];

    # JNA loads libmpv by name; the nix store path is not on the default search
    # list, so point the app's loader helper at it directly. nixpkgs ships the
    # shared library inside the mpv output, not as a standalone libmpv attr.
    environment.variables.SIMPMUSIC_LIBRARY_PATH = "${pkgs.mpv}/lib";
  };
}
