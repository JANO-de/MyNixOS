{ pkgs, repoPath }:
(import ../lib.nix { inherit pkgs repoPath; }) {
  name = "halos1-deploy";
  src = ./halos1-deploy.sh;
  inputs = [ pkgs.git pkgs.openssh ];
}
