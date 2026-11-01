{ pkgs, repoPath }:
(import ../lib.nix { inherit pkgs repoPath; }) {
  name = "halo-dev";
  src = ./halo-dev.sh;
  inputs = [ pkgs.rsync pkgs.openssh ];
}
