{ lib, ... }:

{
  options.modules.programs.heavy = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install heavy IDEs (Android Studio, IntelliJ IDEA, Eclipse, additional JDKs) and office suites (LibreOffice). Disable for low-RAM/small-disk machines to keep the store small enough for a live-USB installer.";
    };
  };

  options.modules.programs.gaming = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install gaming apps (Steam, Prism Launcher, Heroic, GameScope) and their runtimes. Disable for low-RAM/small-disk machines to keep the store small enough for a live-USB installer.";
    };
  };

  options.modules.programs.appstore = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install bazaar, the FlatHub-first app store for GNOME. Independent of gaming (where it used to live by mistake).";
    };
  };

  options.modules.programs.moonlight = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install moonlight-qt, a fullscreen streaming client. On the Surface it renders a Sunshine server's screen so the tablet doubles as an extra monitor.";
    };
  };

  options.modules.programs.deskflow = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install deskflow, to share one keyboard and mouse between machines. Pure install unless a role is set below.";
    };
    role = lib.mkOption {
      type = lib.types.enum [ "none" "server" "client" ];
      default = "none";
      description = "Deskflow role: 'server' serves this host's keyboard/mouse, 'client' consumes another server's. 'none' only installs the binaries.";
    };
    serverAddress = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Host (name or IP) of the deskflow server, for hosts with role = 'client'.";
    };
  };
}