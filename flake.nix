# Flake entry point: inputs + thin outputs. Hosts are the folders in ./hosts; packages, apps and
# the dev shell live in modules/pkgs.
{
  description = "MyNixOS: desktop and laptop";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";

    stylix = {
      url = "github:nix-community/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --- desktop ---
    niri-flake = {
      url = "github:sodiboo/niri-flake/9ee3e13b60643448228353097880521658b2fe0e";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mangowc.url = "github:DreamMaoMao/mangowc/42609fad025602047c9adf883c829658dc95936f";
    noctalia.url = "github:noctalia-dev/noctalia";

    # --- apps ---
    ytm-player = {
      url = "github:peternaame-boop/ytm-player";
    };
    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    #classwork.url = "git+file:///home/jano/Proyectos/Classwork";
    opencode-flake.url = "github:noblepayne/opencode-flake";
    viu.url = "github:viu-media/viu";
    forge = {
      url = "github:JANO-de/Forge-TUI"; # terminal UI for OpenCode
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Native Claude Desktop (Electron) wrapper. Not made to follow our nixpkgs:
    # it still uses the removed `nodePackages` top-level attr.
    claude-desktop.url = "github:k3d3/claude-desktop-linux-flake";

    # --- TUI apps: plain upstream sources, packaged in modules/programs/<name>/pkg ---
    nyaa-si-src = {
      url = "https://codeberg.org/madLinux/nyaa-si/archive/v1.0.0.tar.gz";
      flake = false;
    };
    neo-mangal-src = {
      url = "github:kalebhenrique/neo-mangal/086703a119a7bf72ab229eb7fc176fed877199fa";
      flake = false;
    };

    tuimessenger = {
      url = "github:whyyor/tuimessenger";
    };

    # Rust toolchain (Orchard needs >=1.96)
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --- hardware ---
    # CachyOS kernel (laptop). Release branch = CI-built and cached; do NOT
    # override its nixpkgs input. Pin to 7.2.8 build (avoid 7.3.0 compile).
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/b61eddd37538bf161f54929ae0a283d31df64cef";

    # --- gaming ---
    nix-gaming = {
      url = "github:fufexan/nix-gaming";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:mightyiam/import-tree";

    # --- dev tooling ---
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, import-tree, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [ (import-tree ./parts) ];
    };
}
