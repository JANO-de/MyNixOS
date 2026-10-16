{ ... }:

{
  imports = [
    #./eww.nix
    ./dynisland
    ./end4pc.nix # off by default: modules.desktop.end4pc.enable
  ];
}