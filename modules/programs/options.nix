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
}