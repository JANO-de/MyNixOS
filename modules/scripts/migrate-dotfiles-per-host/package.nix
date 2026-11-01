{ pkgs, repoPath }:
(import ../lib.nix { inherit pkgs repoPath; }) {
  name = "migrate-dotfiles-per-host";
  src = ./migrate-dotfiles-per-host.sh;
  inputs = [ pkgs.git ];
}
