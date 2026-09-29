{ config, pkgs, lib, ... }:

# Bazaar — FlatHub-first app store for GNOME (gnome-software front).
# Split out of gaming.nix where it was filed by mistake.
{
  environment.systemPackages = lib.optionals config.modules.programs.appstore.enable [ pkgs.bazaar ];
}