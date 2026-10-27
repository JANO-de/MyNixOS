# Flake entry point: inputs + outputs. Assembled in nix/ (R-3).
{
  description = "MyNixOS: desktop, laptop and halos1";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --- desktop / session ---
    # MangoWM: NixOS module (session + portals) and Home Manager module
    # (declarative config). Deliberately NOT following our nixpkgs: it builds
    # against its own pinned wlroots/scenefx, which the stable channel may not
    # carry yet. If you want to share nixpkgs, add `inputs.nixpkgs.follows`.
    mango.url = "github:mangowm/mango";

    # Hyprland (flake package: plugins must match its exact version). Do NOT add
    # inputs.nixpkgs.follows here, it would make the Cachix cache useless.
    hyprland.url = "github:hyprwm/Hyprland";
    hyprgrass = {
      url = "github:horriblename/hyprgrass";
      inputs.hyprland.follows = "hyprland";
    };

    # Chronos: niri fork + Quickshell shell (also used by the Surface).
    chronos.url = "git+file:///home/jano/Proyectos/chronos";

    # --- apps ---
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    opencode-flake.url = "github:noblepayne/opencode-flake";
    forge = {
      url = "github:JANO-de/Forge-TUI"; # terminal UI for OpenCode
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Native Claude Desktop (Electron) wrapper. Not made to follow our nixpkgs:
    # it still uses the removed `nodePackages` top-level attr.
    claude-desktop.url = "github:k3d3/claude-desktop-linux-flake";

    # Arcticons line-art icons (SVG), recoloured by halo-recolor-icons.
    arcticons = {
      url = "github:Donnnno/Arcticons";
      flake = false;
    };
    # Rust toolchain (Orchard needs >=1.96)
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # --- hardware ---
    # linux-surface kernel, IPTS touch, Marvell wifi firmware (surface).
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    # CachyOS kernel (laptop). Release branch = CI-built and cached; do NOT
    # override its nixpkgs input. Pin to 7.2.8 build (avoid 7.3.0 compile).
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/b61eddd37538bf161f54929ae0a283d31df64cef";
  };

  outputs = inputs: import ./nix inputs;
}
