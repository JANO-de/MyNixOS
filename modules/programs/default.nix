{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.modules.programs = {
    enable = lib.mkEnableOption "the program sets (lean/full profile, deskflow)";

    profile = lib.mkOption {
      type = lib.types.enum [
        "full"
        "lean"
      ];
      default = "full";
      description = "Which program set this host gets. 'lean' is for low-RAM / small-disk machines (the Surface).";
    };

    deskflow = {
      role = lib.mkOption {
        type = lib.types.enum [
          "none"
          "server"
          "client"
        ];
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
    ./apps.nix
    ./office.nix
    ./files.nix
    ./ai.nix
    ./spotify.nix
    ./deskflow.nix
    ./orchard
    ./nixscout
    ./nyaa-si
    ./neo-mangal
    ./vid-dl
  ];
}
