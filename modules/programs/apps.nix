# Everyday GUI apps for the full (desktop/laptop) hosts: browsers, chat,
# notes/office, and the Bazaar app store.
{ config, pkgs, lib, inputs, ... }:

{
  environment.systemPackages =
    (with pkgs; [
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default

      dissent
      telegram-desktop
      vesktop
      zapzap
      simplex-chat-desktop

      obsidian
      wl-screenrec
      thunderbird
    ])
    # Bazaar: FlatHub-first app store.
    ++ lib.optionals config.modules.programs.appstore.enable [ pkgs.bazaar ];
}
