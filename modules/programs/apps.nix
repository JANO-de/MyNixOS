# Everyday apps: browsers, chat, password manager, Claude, OpenCode, VPN.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.modules.programs.apps;
  system = pkgs.stdenv.hostPlatform.system;
in
{
  options.modules.programs.apps.enable =
    lib.mkEnableOption "everyday apps (Zen, Chromium, Vesktop, Bazaar, Bitwarden, Claude Desktop, OpenCode, Proton VPN)";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      inputs.zen-browser.packages.${system}.default
      chromium
      vesktop
      bazaar
      bitwarden-cli
      inputs.claude-desktop.packages.${system}.claude-desktop-with-fhs
      inputs.opencode-flake.packages.${system}.opencode-avx
      proton-vpn
    ];
  };
}
