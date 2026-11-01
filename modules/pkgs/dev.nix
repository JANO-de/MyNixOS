{ inputs, system }:
let
  pkgs = import inputs.nixpkgs { inherit system; };
  nixfmt = pkgs.nixfmt;
in
{
  shells = {
    default = pkgs.mkShell {
      packages = [
        pkgs.rustc
        pkgs.cargo
        pkgs.pkg-config
        pkgs.gtk4
        pkgs.libadwaita
        pkgs.glib
        pkgs.sqlite
        nixfmt
      ];
    };
  };
  formatter = nixfmt;
  checks = {
    nixfmt = pkgs.runCommand "nixfmt-check" { } ''
      ${nixfmt}/bin/nixfmt --check ${../../flake.nix} ${./default.nix} ${./dev.nix}
      touch $out
    '';
  };
}
