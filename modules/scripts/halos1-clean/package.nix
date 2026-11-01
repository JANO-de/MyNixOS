{ pkgs, repoPath }:
(import ../lib.nix { inherit pkgs repoPath; }) {
  name = "halos1-clean";
  src = ./halos1-clean.sh;
  inputs = [ pkgs.openssh ];
}
