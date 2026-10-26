# Droidloom (Android apps in native Wayland windows), opt-in: modules.desktop.droidloom.enable.
# Upstream: github.com/denialwm/droidloom (Arch only). We do NOT rebuild it: we unpack upstream's
# prebuilt pacman packages (release "packages", 0.1.0-25) and rebuild the Arch filesystem layout
# with symlinks (/usr/lib/droidloom, /usr/share/droidloom, /usr/bin/*), because the binaries,
# units and cell template hard-code those paths.
# First start: `droidloomctl start` (as your user; polkit asks once to create /etc/droidloom).
# Rescue: set enable = false and rebuild, or pick the previous generation in the boot menu.
{ config, lib, pkgs, ... }:
let
  cfg = config.modules.desktop.droidloom;
  rel = "0.1.0-25";
  base = "https://github.com/denialwm/droidloom/releases/download/packages";

  # Host-side programs (small): patched for NixOS.
  runtimePkg = pkgs.stdenv.mkDerivation {
    pname = "droidloom-runtime";
    version = rel;
    src = pkgs.fetchurl {
      url = "${base}/droidloom-runtime-${rel}-x86_64.pkg.tar.zst";
      hash = "sha256-qCQpQFcmdHH425swDmADWxP7JpaZvN4LGfg/WADpJcE=";
    };
    nativeBuildInputs = [ pkgs.zstd pkgs.autoPatchelfHook ];
    buildInputs = [ pkgs.stdenv.cc.cc.lib pkgs.libgbm pkgs.libxkbcommon pkgs.pipewire ]; # autoPatchelf only searches buildInputs (droidloom-audio needs libpipewire)
    # libraries the Rust code may dlopen (wayland-sys, drm, pipewire, EGL/Vulkan)
    runtimeDependencies = [ pkgs.wayland pkgs.libdrm pkgs.libxkbcommon pkgs.libgbm pkgs.pipewire pkgs.libGL pkgs.vulkan-loader ];
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out
      tar -I zstd -xf $src -C $out --no-same-owner --exclude=.BUILDINFO --exclude=.MTREE --exclude=.PKGINFO
    '';
  };

  # Android images + Android-side binaries (~1 GB packed). Android code: never patch it.
  imagePkg = pkgs.stdenvNoCC.mkDerivation {
    pname = "droidloom-image";
    version = rel;
    src = pkgs.fetchurl {
      url = "${base}/droidloom-image-${rel}-x86_64.pkg.tar.zst";
      hash = "sha256-Y0nvtglU179FqUZnBD2hdx1z1lZwt/wZFdhkVTY88eg=";
    };
    nativeBuildInputs = [ pkgs.zstd ];
    dontUnpack = true;
    dontFixup = true;
    installPhase = ''
      mkdir -p $out
      tar -I zstd -xf $src -C $out --no-same-owner --exclude=.BUILDINFO --exclude=.MTREE --exclude=.PKGINFO
    '';
  };

  # Arch layout: copy the small runtime tree, symlink every image entry next to the helper, so
  # that std::env::current_exe() of the programs still finds ../lib/droidloom/*.
  root = pkgs.runCommand "droidloom-root-${rel}" { } ''
    mkdir -p $out
    cp -a ${runtimePkg}/usr $out/usr
    chmod -R u+w $out/usr
    for f in ${imagePkg}/usr/lib/droidloom/*; do
      ln -s "$f" "$out/usr/lib/droidloom/$(basename "$f")"
    done
  '';

  # systemd units straight from the package (they use /usr/bin/..., linked in the activation script).
  units = pkgs.runCommand "droidloom-units-${rel}" { } ''
    mkdir -p $out/lib
    cp -r ${runtimePkg}/usr/lib/systemd $out/lib/systemd
  '';

  bins = [ "droidloomd" "droidloom-wayland" "droidloom-audio" "droidloom-applications" "droidloom-doctor" "droidloom-supervisor" "droidloomctl" ];
in
{
  options.modules.desktop.droidloom = {
    enable = lib.mkEnableOption "Droidloom: Android apps in native Wayland windows (x86_64, Intel/AMD GPU)";
    user = lib.mkOption {
      type = lib.types.str;
      default = "jano";
      description = "Desktop user that runs Android apps (needs the video and render groups).";
    };
    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Start the Android runtime with the graphical session (off: run `droidloomctl start`).";
    };
  };

  config = lib.mkIf cfg.enable {
    security.polkit.enable = true;
    users.users.${cfg.user}.extraGroups = [ "video" "render" ];

    # Arch paths that the binaries, units and cell template hard-code.
    system.activationScripts.droidloom = lib.stringAfter [ "etc" ] ''
      mkdir -p /usr/bin /usr/lib /usr/share
      ln -sfn ${root}/usr/lib/droidloom /usr/lib/droidloom
      ln -sfn ${root}/usr/share/droidloom /usr/share/droidloom
      ${lib.concatMapStringsSep "\n" (b: "ln -sfn ${root}/usr/bin/${b} /usr/bin/${b}") bins}
      ln -sfn ${config.systemd.package}/bin/systemctl /usr/bin/systemctl
      ln -sfn ${pkgs.glibc.getent}/bin/getent /usr/bin/getent
      ln -sfn /run/wrappers/bin/pkexec /usr/bin/pkexec
    '';

    environment.systemPackages = [
      (pkgs.linkFarm "droidloomctl" [ { name = "bin/droidloomctl"; path = "${root}/usr/bin/droidloomctl"; } ])
    ];

    systemd.packages = [ units ];

    # The Arch unit has [Install] WantedBy=multi-user.target: here it starts on demand (droidloom.service pulls it in).
    systemd.services.droidloomd.path = with pkgs; [ coreutils iproute2 nftables iptables util-linux e2fsprogs android-tools kmod systemd ];
    systemd.services.droidloomd.serviceConfig.IPAccounting = false;
    systemd.user.services.droidloom = {
      path = with pkgs; [ coreutils systemd ];
      wantedBy = lib.optional cfg.autoStart "graphical-session.target";
    };
    systemd.user.services.droidloom-applications.path = with pkgs; [ coreutils ];
  };
}
