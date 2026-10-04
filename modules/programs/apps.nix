# Everyday GUI apps for the full (desktop/laptop) hosts: browsers, chat,
# notes/office, and the Bazaar app store.
{ config, pkgs, lib, inputs, ... }:

{
  environment.systemPackages =
    (with pkgs; [
      librewolf
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default

      dissent
      vesktop
      zapzap
      simplex-chat-desktop

      obsidian
      wl-screenrec
      thunderbird
    ])
    ++ lib.optionals config.modules.programs.heavy.enable [ pkgs.libreoffice ]
    # Bazaar: FlatHub-first app store.
    ++ lib.optionals config.modules.programs.appstore.enable [ pkgs.bazaar ];
}
