{ pkgs, repoPath }:
(import ../lib.nix { inherit pkgs repoPath; }) {
  name = "config-backup";
  src = ./config-backup.sh;
  inputs = [ ];
}
