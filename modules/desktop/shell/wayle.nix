# Wayle — a Wayland Elements shell (bar, notifications, OSD, wallpaper) for
# the niri session. Compositor-agnostic, works on top of niri via wlr-layer-shell.
#
# This replaces the iNiR/Qickshell shell. The home-manager `services.wayle`
# module owns the package, the generated config.toml and a user systemd unit
# (`wayle shell`) bound to graphical-session.target — the same target niri's
# systemd integration activates, so wayle starts right after the compositor.
# `ConditionEnvironment=WAYLAND_DISPLAY` matches how niri publishes the session
# env, and `autoInstallDependencies` keeps wayle's theme-provider working.
#
# Keep `programs.dconf.enable` around: niri.nix writes the shell's icon theme
# through a dconf database, and on a niri host the only other enabler of that
# module is gnome/nix, which is not enabled here.
{ ... }:

{
  home-manager.users.jano.services.wayle = {
    enable = true;
    # stock layout: top bar (media / clock / battery / volume). Later users can
    # override settings toggling into their own layout without touching this.
    settings = { };
  };

  programs.dconf.enable = true;

  # wayle's on-screen toggles (volume/brightness OSD) read keyboard devices,
  # which requires membership in the `input` group.
  users.users.jano.extraGroups = [ "input" ];
}