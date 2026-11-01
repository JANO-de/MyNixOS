# Module loader: the only file that decides what gets imported from modules/.
# A folder with its own default.nix is one module; otherwise every *.nix file
# below is a module. Folders named pkg, src, dotfiles and pkgs hold packages
# and sources, not NixOS modules, so they are skipped. Order is alphabetical.
# Every module is off until a host enables it, e.g. modules.dev.java = true;
{ lib, ... }:
let
  skip = [
    "pkg"
    "src"
    "dotfiles"
    "pkgs"
  ];

  walk =
    dir:
    lib.concatLists (
      lib.mapAttrsToList (
        name: type:
        let
          path = dir + "/${name}";
        in
        if type == "directory" then
          if builtins.elem name skip then
            [ ]
          else if builtins.pathExists (path + "/default.nix") then
            [ path ]
          else
            walk path
        else if type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix" then
          [ path ]
        else
          [ ]
      ) (builtins.readDir dir)
    );
in
{
  imports = walk ./.;
}
