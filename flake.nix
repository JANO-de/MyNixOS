# Flake entry point: inputs + thin outputs. Hosts are the folders in ./hosts; packages, apps and
# the dev shell live in modules/pkgs.
{
  description = "MyNixOS: desktop and laptop";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --- apps ---
    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    #classwork.url = "git+file:///home/jano/Proyectos/Classwork";
    opencode-flake.url = "github:noblepayne/opencode-flake";
    forge = {
      url = "github:JANO-de/Forge-TUI"; # terminal UI for OpenCode
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Dux suite apps. If one fails with a Go version error (needs Go 1.27),
    # remove its `inputs.nixpkgs.follows` line so it uses its own nixpkgs pin.
    dux-files = {
      url = "github:duxlabs-dev/dux-files";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dux-search = {
      url = "github:duxlabs-dev/dux-search";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dux-calendar = {
      url = "github:duxlabs-dev/dux-calendar/v2.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dux-gop = {
      url = "github:duxlabs-dev/dux-gop";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Native Claude Desktop (Electron) wrapper. Not made to follow our nixpkgs:
    # it still uses the removed `nodePackages` top-level attr.
    claude-desktop.url = "github:k3d3/claude-desktop-linux-flake";

    # Rust toolchain (Orchard needs >=1.96)
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --- hardware ---
    # CachyOS kernel (laptop). Release branch = CI-built and cached; do NOT
    # override its nixpkgs input. Pin to 7.2.8 build (avoid 7.3.0 compile).
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/b61eddd37538bf161f54929ae0a283d31df64cef";
  };

  outputs =
    inputs@{ nixpkgs, self, ... }:
    let
      system = "x86_64-linux";
      theme = import ./modules/theme/palette.nix;
      pkgsOut = import ./modules/pkgs { inherit inputs system; };
      dev = import ./modules/pkgs/dev.nix { inherit inputs system; };
      mkHost =
        host:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs theme; };
          modules = [
            inputs.home-manager.nixosModules.home-manager
            inputs.forge.nixosModules.default
            inputs.dux-files.nixosModules.dux-files # defines programs.dux-files
            ./hosts/${host}/default.nix
            {
              nixpkgs.overlays = [
                inputs.rust-overlay.overlays.default
                self.overlays.default
              ];
            }
          ];
        };
      hosts = builtins.attrNames (
        nixpkgs.lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./hosts)
      );
    in
    {
      packages.${system} = pkgsOut.packages;
      apps.${system} = pkgsOut.apps;
      overlays.default = pkgsOut.overlay;
      nixosModules.orchard = ./modules/programs/orchard/default.nix;
      nixosModules.niXscout = ./modules/programs/nixscout/default.nix;
      nixosConfigurations = nixpkgs.lib.genAttrs hosts mkHost;
      devShells.${system} = dev.shells;
      formatter.${system} = dev.formatter;
      checks.${system} = dev.checks;
    };
}
