# Core module aggregator: boot, nix, users, locale, fonts, shell, home-manager.
{ ... }@args: {
  imports = [
    ./boot.nix
    ./nix.nix
    ./users.nix
    ./locale.nix
    ./fonts.nix
    ./shell.nix
    ./home-manager.nix
  ];
}
