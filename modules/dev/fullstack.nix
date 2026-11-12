# Full-stack development: editor, compilers, Rust (cargo), language tooling, Nix tooling, nix-ld.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.dev.fullstack;
in
{
  options.modules.dev.fullstack = lib.mkEnableOption "full-stack development tools";

  config = lib.mkIf cfg {
    environment.systemPackages = with pkgs; [
      vscodium
      gcc
      gdb
      clang-tools
      cmake
      cargo
      rustc
      rustup
      ninja
      pkg-config
      python3
      ruff
      uv
      nodejs_22
      nixd
      nixfmt
      direnv
    ];

    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc.lib
        zlib
        openssl
      ];
    };
  };
}
