# Primary user account.
{ pkgs, ... }:

{
  users.users.jano = {
    isNormalUser = true;
    description = "jano";
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" ];
    autoSubUidGidRange = false;
    subUidRanges = [ { startUid = 100000; count = 100000; } ];
    subGidRanges = [ { startGid = 100000; count = 100000; } ];
  };
}
