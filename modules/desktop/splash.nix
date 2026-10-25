# Halo boot splash (Plymouth): quiet boot, a breathing ring until the greeter appears.
{ config, lib, pkgs, ... }:
let
  cfg = config.modules.desktop.haloSplash;
  theme = pkgs.runCommand "plymouth-theme-halo" { } ''
    d=$out/share/plymouth/themes/halo
    mkdir -p $d
    cp ${./plymouth/ring.png} $d/ring.png
    cp ${./plymouth/halo.script} $d/halo.script
    cat > $d/halo.plymouth <<EOF
    [Plymouth Theme]
    Name=Halo
    Description=Halo boot splash
    ModuleName=script

    [script]
    ImageDir=$d
    ScriptFile=$d/halo.script
    EOF
  '';
in
{
  options.modules.desktop.haloSplash.enable = lib.mkEnableOption "the Halo Plymouth boot splash and a quiet boot";

  config = lib.mkIf cfg.enable {
    boot.plymouth = {
      enable = true;
      theme = "halo";
      themePackages = [ theme ];
    };
    boot.consoleLogLevel = 0;
    boot.initrd.verbose = false;
    boot.kernelParams = [ "quiet" "splash" "loglevel=3" "udev.log_priority=3" "rd.systemd.show_status=false" ];
    boot.initrd.kernelModules = [ "i915" ]; # early KMS: the splash starts at native resolution
  };
}
