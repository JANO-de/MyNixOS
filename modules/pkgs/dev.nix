# Dev tooling: treefmt (nix fmt), formatting check, pre-commit hook, dev shell.
{
  inputs,
  system,
  self,
}:
let
  pkgs = import inputs.nixpkgs { inherit system; };
  treefmt = inputs.treefmt-nix.lib.evalModule pkgs {
    projectRootFile = "flake.nix";
    programs.nixfmt.enable = true;
  };
  hooks = inputs.git-hooks.lib.${system}.run {
    src = self;
    hooks.treefmt = {
      enable = true;
      package = treefmt.config.build.wrapper;
    };
  };
in
{
  shells.default = pkgs.mkShell {
    packages = [
      pkgs.rustc
      pkgs.cargo
      pkgs.pkg-config
      pkgs.gtk4
      pkgs.libadwaita
      pkgs.glib
      pkgs.sqlite
      treefmt.config.build.wrapper
    ];
    inherit (hooks) shellHook;
  };
  formatter = treefmt.config.build.wrapper;
  checks = {
    formatting = treefmt.config.build.check self;
    pre-commit = hooks;
  };
}
