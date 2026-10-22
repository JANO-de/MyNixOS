{
  description = "MyNixOS: desktop, laptop and surface";

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

    # --- hardware ---
    # CachyOS kernel (laptop). Release branch = CI-built and cached; do NOT
    # override its nixpkgs input.
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";
    # linux-surface kernel, IPTS touch, Marvell wifi firmware (surface).
    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      mango,
      forge,
      nix-cachyos-kernel,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      theme = import ./modules/theme.nix;

      mkHost =
        {
          host,
          cachyos ? false,
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs theme; };
          modules = [
            home-manager.nixosModules.home-manager
            forge.nixosModules.default
            mango.nixosModules.mango
            ./hosts/${host}/default.nix
          ]
          # CachyOS kernel overlay: only the laptop boots that kernel. The
          # Surface must NOT get it (it relies on nixos-hardware's patched
          # linux-surface kernel).
          ++ nixpkgs.lib.optional cachyos {
            nixpkgs.overlays = [ nix-cachyos-kernel.overlays.pinned ];
          };
        };
    in
    {
      nixosConfigurations = {
        desktop = mkHost { host = "desktop"; };
        laptop = mkHost {
          host = "laptop";
          cachyos = true;
        };
        surface = mkHost { host = "surface"; };
      };
    };
}
