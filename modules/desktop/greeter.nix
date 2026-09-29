{ config, lib, pkgs, ... }:

# Which login screen (greeter) runs.
#
# The two greeters in nixpkgs are not interchangeable: GDM is the GNOME one and
# is what a GNOME session expects, SDDM is the one that themes nicely (the same
# catppuccin theme the Plasma desktop already uses here). Owning the choice in
# one place is also what keeps the two from being enabled at the same time,
# which systemd would refuse to start.
#
# Hosts with Plasma keep SDDM regardless, since that is what the Plasma session
# is built against; everything else follows the option.
let
  sddmWanted = config.modules.desktop.displayManager == "sddm"
    || config.modules.desktop.plasma.enable;
in
{
  config = {
    services.displayManager.sddm = lib.mkIf sddmWanted {
      enable = true;
      theme = "${pkgs.catppuccin-sddm}/share/sddm/themes/catppuccin-mocha-mauve";
    };
  };
}
