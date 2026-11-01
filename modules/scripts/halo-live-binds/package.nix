{ pkgs, repoPath }:
(import ../lib.nix { inherit pkgs repoPath; }) {
  name = "halo-live-binds";
  src = ./halo-live-binds.sh;
  inputs = [ pkgs.openssh ];
}
