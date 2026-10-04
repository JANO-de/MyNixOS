{
  description = "MyNixOS configuration";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    inir.url = "github:snowarch/inir";

    opencode-flake.url = "github:noblepayne/opencode-flake";

    # CachyOS kernel — release branch = CI-built & cached on their Attic.
    # Do NOT override its nixpkgs input (patches/kernel must stay in sync).
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    # Hardware enablement for the Surface (linux-surface patched kernel,
    # IPTS touch, Marvell wifi firmware, thermald, surface-control).
    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  nixConfig = {
    extra-substituters = [
      "https://attic.xuyh0120.win/lantian"
    ];
    extra-trusted-public-keys = [
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
    ];
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, zen-browser, nix-cachyos-kernel, nixos-hardware, opencode-flake, inir }@inputs:
  let
    system = "x86_64-linux";
    lib = nixpkgs.lib;
    theme = import ./modules/theme.nix;

    # niriEnabled=true: niri + iNiR shell; false: no niri (Plasma on the Surface).
    # Passed explicitly (no module default) so the defaulted-arg probe can't recurse.
    mkHost = { host, niriEnabled ? true, cachyos ? true }: lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs theme niriEnabled; };
      modules = [
        inputs.home-manager.nixosModules.home-manager
        ./hosts/${host}/default.nix
      ]
      # CachyOS kernel overlay (pinned = built against their nixpkgs, uses binary cache)
      ++ lib.optional cachyos ({ ... }: { nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ]; });
    };
  in
  {
    nixosConfigurations = {
      laptop = mkHost { host = "laptop"; };
      desktop = mkHost { host = "desktop"; };

      # Microsoft Surface Pro 5 (i5 / 8GB / 128GB), Plasma 6 on Wayland.
      # Deliberately NO CachyOS overlay: the Surface relies on nixos-hardware's
      # linux-surface patched kernel (SAM/IPTS/thermald) + the in-tree Marvell
      # mwifiex wifi driver; the CachyOS kernel would drop all of that.
      surface = mkHost { host = "surface"; niriEnabled = false; cachyos = false; };

      # Live USB image used to install `surface` (and to rescue it). Same GNOME
      # installer as upstream, plus nixos-hardware's Surface support (patched
      # kernel + iptsd + redistributable firmware), so touch and Wi-Fi work in
      # the live session where the official image has neither.
      installer = lib.nixosSystem {
        inherit system;
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix"
          inputs.nixos-hardware.nixosModules.microsoft-surface-pro-intel
          ./modules/installer/surface-live.nix
        ];
      };

      # Tiny first-stage system for the SP5 (see hosts/surface-bootstrap/default.nix).
      surface-bootstrap = lib.nixosSystem {
        inherit system;
        modules = [ ./hosts/surface-bootstrap/default.nix ];
      };
    };

    packages.${system} = {
      nixos-gnome-iso = self.nixosConfigurations.installer.config.system.build.isoImage;
    };
  };
}
