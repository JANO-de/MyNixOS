# Droidloom on NixOS, repackaged from the prebuilt pacman pair
# (droidloom-runtime + droidloom-image). UNTESTED: written without network or
# Nix build access, so expect path fixes on the first build.
#
# Why binary: upstream's build needs ~120 GiB free, 32 GiB RAM, rootless Podman
# and an Arch container. Not possible on a Surface Pro 5 (8 GB / 128 GB).
# Build it on a bigger machine if you want your own packages, or use the
# upstream release archives.
#
# Setup:
#   1. https://github.com/denialwm/droidloom/releases (tag "packages"):
#      copy the links of the matching droidloom-runtime-*.pkg.tar.zst and
#      droidloom-image-*.pkg.tar.zst (same version-release!).
#   2. Fill `runtimePkg` / `imagePkg`, then hash each:
#        nix store prefetch-file --hash-type sha256 <url>
#   3. Import in hosts/surface/default.nix, rebuild.
#   4. As your normal user inside the Plasma (Wayland) session:
#        droidloomctl start --mode mobile      # tablet-style fullscreen apps
#        droidloomctl launch com.android.settings
#      First start asks for admin auth (creates /etc/droidloom and
#      /var/lib/droidloom). Packages are unsigned upstream: you trust their host.
#
# Do not run Waydroid and Droidloom at the same time (both want binder/GPU).
{ config, lib, pkgs, ... }:

let
  runtimePkg = pkgs.fetchurl {
    url = "https://github.com/denialwm/droidloom/releases/download/packages/droidloom-runtime-0.1.0-23-x86_64.pkg.tar.zst";
    hash = "sha256-EK8oY7yrusdY8JtYdTBHFlvGQTbRVzuwbfECU0REYQM=";
  };
  imagePkg = pkgs.fetchurl {
    url = "https://github.com/denialwm/droidloom/releases/download/packages/droidloom-image-0.1.0-23-x86_64.pkg.tar.zst";
    hash = "sha256-srAlwBIqA2TGnM7XfwNljh++OjJOyLZrP49Qvh9QRqI=";
  };

  droidloom = pkgs.stdenv.mkDerivation {
    pname = "droidloom";
    version = "preview";
    dontUnpack = true;

    nativeBuildInputs = [ pkgs.autoPatchelfHook pkgs.zstd pkgs.gnutar ];
    buildInputs = with pkgs; [
      stdenv.cc.cc.lib systemd wayland libxkbcommon libdrm libgbm libGL
      pipewire zlib
    ];

    installPhase = ''
      mkdir -p $out x
      for p in ${runtimePkg} ${imagePkg}; do
        tar --zstd -xf $p -C x --exclude='.PKGINFO' --exclude='.MTREE' \
            --exclude='.BUILDINFO' --exclude='.INSTALL'
      done
      cp -r x/usr/* $out/
      [ -d x/etc ] && cp -r x/etc $out/etc || true

      # Text files only (units, desktop files, scripts): point /usr -> store.
      # Compiled binaries keep /usr/lib/droidloom, provided via tmpfiles below.
      grep -rIl '/usr/' $out | xargs -r sed -i "s|/usr/|$out/|g"
    '';
    meta = {
      description = "Android apps in Wayland windows (binary repackage)";
      license = lib.licenses.gpl3Plus;
      platforms = [ "x86_64-linux" ];
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    };
  };
in
{
  environment.systemPackages = [ droidloom ];

  # Units shipped in the package (droidloomd.service, user droidloom.service).
  systemd.packages = [ droidloom ];

  # Hardcoded /usr/lib/droidloom inside the binaries and the setup helper.
  systemd.tmpfiles.rules = [
    "d /usr/lib 0755 root root -"
    "L+ /usr/lib/droidloom - - - - ${droidloom}/lib/droidloom"
    "d /etc/droidloom 0755 root root -"
    "d /var/lib/droidloom 0755 root root -"
  ];

  # Android cell needs binderfs, namespaces, loop devices and a DRM render node.
  # nixpkgs kernels (incl. linux-surface via nixos-hardware) normally have these;
  # confirm with droidloom's doctor or:  zcat /proc/config.gz | grep -i binder
  boot.kernelModules = [ "loop" ];
  hardware.graphics.enable = true;          # Intel HD 620 (Mesa, GLES 3.2)
  security.polkit.enable = true;            # first-start auth + droidloomd.service rule
  services.pipewire.enable = lib.mkDefault true;

  # One Android runtime at a time.
  # modules.services.waydroid.enable = lib.mkForce false;   # uncomment to switch
}
