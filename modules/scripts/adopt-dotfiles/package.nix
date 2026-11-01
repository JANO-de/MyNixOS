{ pkgs, repoPath }:
(import ../lib.nix { inherit pkgs repoPath; }) {
  name = "adopt-dotfiles";
  src = ./adopt-dotfiles.sh;
  inputs = [ pkgs.rsync ];
}
