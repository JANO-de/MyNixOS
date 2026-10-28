{ config, lib, pkgs, ... }:

{
  options.modules.programs = {
    profile = lib.mkOption {
      type = lib.types.enum [ "full" "lean" ];
      default = "full";
      description = "Which program set this host gets. 'lean' is for low-RAM / small-disk machines (the Surface).";
    };

    deskflow = {
      role = lib.mkOption {
        type = lib.types.enum [ "none" "server" "client" ];
        default = "none";
        description = "Deskflow keyboard/mouse sharing: 'server' serves this host's input, 'client' consumes another server's, 'none' only installs the binary.";
      };
      serverAddress = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Host (name or IP) of the deskflow server, for role = 'client'.";
      };
    };
  };

  imports = [
    ./lean.nix
    ./full.nix
    ./deskflow.nix
    ./niXscout.nix
  ];
}
