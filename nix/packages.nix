{ inputs, system }:
let
  inherit (inputs) nixpkgs self;
  pkgs = import nixpkgs { inherit system; };
  orchardPkg =
    let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ inputs.rust-overlay.overlays.default ];
        config.allowUnfree = true;
      };
    in
    pkgs.callPackage ../modules/programs/orchard/pkg/default.nix { };
  niXscoutPkg = pkgs.callPackage ../modules/programs/nixscout/pkg/default.nix { };
  scriptPkg =
    name:
    import ../modules/scripts/${name}/package.nix {
      inherit pkgs;
      repoPath = "$HOME/Proyectos/MyNixOS";
    };
  adoptDotfilesPkg = scriptPkg "adopt-dotfiles";
  migrateDotfilesPkg = scriptPkg "migrate-dotfiles-per-host";
  hyprmonPkg = pkgs.callPackage ../modules/pkgs/hyprmon/default.nix { };
  localsendCliPkg = pkgs.callPackage ../modules/pkgs/localsend-cli/default.nix { };
  matugenPkg = pkgs.callPackage ../modules/pkgs/matugen/default.nix { };
in
{
  packages = {
    orchard = orchardPkg;
    niXscout = niXscoutPkg;
    hyprmon = hyprmonPkg;
    localsend-cli = localsendCliPkg;
    matugen = matugenPkg;
  };
  apps = {
    orchard = {
      type = "app";
      program = "${orchardPkg}/bin/orchard";
    };
    niXscout = {
      type = "app";
      program = "${niXscoutPkg}/bin/niXscout";
    };
    adopt-dotfiles = {
      type = "app";
      program = "${adoptDotfilesPkg}/bin/adopt-dotfiles";
    };
    migrate-dotfiles-per-host = {
      type = "app";
      program = "${migrateDotfilesPkg}/bin/migrate-dotfiles-per-host";
    };
  };
  overlay = final: prev: {
    orchard = final.callPackage ../modules/programs/orchard/pkg/default.nix { };
    niXscout = final.callPackage ../modules/programs/nixscout/pkg/default.nix { };
    hyprmon = final.callPackage ../modules/pkgs/hyprmon/default.nix { };
    localsend-cli = final.callPackage ../modules/pkgs/localsend-cli/default.nix { };
    matugen = final.callPackage ../modules/pkgs/matugen/default.nix { };
  };
}
