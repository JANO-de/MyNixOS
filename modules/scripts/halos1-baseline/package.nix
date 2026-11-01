{ pkgs, repoPath }:
(import ../lib.nix { inherit pkgs repoPath; }) {
  name = "halos1-baseline";
  src = ./halos1-baseline.sh;
  inputs = [ ];
}
