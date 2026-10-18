# Denial on the Surface Pro 5, using denialwm/denial's own first-party
# NixOS flake and module, confirmed from their own docs:
# "Denial ships its Nix package, overlay, and NixOS module in this
# repository... Normal installations reuse a separately cached engine."
# UNTESTED: no Nix/network in the authoring sandbox.
#
# flake.nix: input is `denial.url = "github:denialwm/denial";` with NO
# nixpkgs.follows override (the docs say following changes the engine
# cache key and forces a from-source rebuild). The real Cachix
# substituter + key live in flake.nix's top-level nixConfig, since a
# flake's nixConfig isn't honored when it's only used as an input --
# the nix.settings line below is belt-and-suspenders for later rebuilds,
# not what makes the FIRST build hit the cache.
#
# mkHost modules list: nothing else needed, this file imports the module.
#
# WARNING: per upstream docs, a cache MISS does a full source build that
# has needed 48+ GiB of temporary Nix store space on their validation
# host (they recommend 64 GiB free). The Surface has a 128 GB disk
# already carrying Plasma + droidloom + everything else -- if the build
# doesn't say "copying path ... from 'https://denial.cachix.org'" early
# on and instead starts compiling Flutter/Skia/Dart from source, stop
# and check the substituter/key before letting it eat your disk.
{ config, lib, pkgs, inputs, ... }:
{
  imports = [ inputs.denial.nixosModules.default ];

  programs.denial.enable = true;           # adds the "Denial" session to the display manager; Plasma stays default
  # programs.denial.plugins.enable = true; # optional Plugin Manager (denial-plugin-manager), not needed to start

  # Belt-and-suspenders: the real cache config is flake.nix's nixConfig
  # (required for it to apply on the first build). This just keeps it
  # configured for later rebuilds / direct `nix build` calls too.
  nix.settings = {
    substituters = [ "https://denial.cachix.org" ];
    trusted-public-keys = [
      "denial.cachix.org-1:wd8YTnvPmugFrtdMJWtR1XdVknR3/g2nmBJkT+vAruo="
    ];
  };

  # The module already registers Xwayland, polkit, the wlroots
  # screenshot/screencast portal, and a polkit auth agent by default --
  # no need to also set programs.xwayland.enable / security.polkit.enable
  # here, they were only needed for the old binary-repackage version.
  security.rtkit.enable = true;            # Denial's unprivileged priority fallback
  hardware.graphics.enable = true;         # Intel HD 620 (Mesa)

  # Module defaults you may want to flip later if they clash with your
  # existing desktop setup (see upstream docs for the exact option names):
  #   programs.denial.polkitAgent.enable = false;  # if you already run one
  #   programs.denial.ddc.enable = false;          # if you don't need DDC monitor control

  # If rendering glitches on the HD 620: DENIA_FLUTTER_RENDERER=skia (documented override).
  # If startup logs "GBM backend initialization failure" for an already-open
  # DRM device, that's misleading -- it means the device DID open; check the
  # Mesa loader output just before it (often a GLIBC_* symbol mismatch) rather
  # than treating it as a DRM access problem.
}
