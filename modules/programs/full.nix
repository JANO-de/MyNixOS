# Full profile (desktop, laptop): a bundle. It switches on every program module a full machine has.
# Members use mkDefault, so a host can still turn one off, e.g. modules.programs.ai.enable = false.
{ config, lib, ... }:
let
  cfg = config.modules.programs;
in
{
  config = lib.mkIf (cfg.enable && cfg.profile == "full") {
    modules.dev.java = lib.mkDefault true;
    modules.dev.fullstack = lib.mkDefault true;

    modules.programs.apps.enable = lib.mkDefault true;
    modules.programs.office.enable = lib.mkDefault true;
    modules.programs.files.enable = lib.mkDefault true;
    modules.programs.ai.enable = lib.mkDefault true;
    modules.programs.spotify.enable = lib.mkDefault true;
  };
}
