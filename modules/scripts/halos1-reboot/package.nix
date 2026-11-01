{ pkgs, repoPath }:
(import ../lib.nix { inherit pkgs repoPath; }) {
  name = "halos1-reboot";
  src = ./halos1-reboot.sh;
  inputs = [ pkgs.openssh ];
}
