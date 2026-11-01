{ pkgs, repoPath }:
(import ../lib.nix { inherit pkgs repoPath; }) {
  name = "halo-ipc";
  src = ./halo-ipc.sh;
  inputs = [ pkgs.openssh ];
}
