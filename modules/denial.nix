# Denial (Flutter-native Wayland compositor) for NixOS, repackaged from the
# signed x86-64 Arch packages. UNTESTED: written without network/build access.
#
# Why binary: Denial needs a custom Flutter engine + Skia fork (GN/Ninja build,
# many GB + hours). Not feasible on an 8GB/128GB Surface or as a normal Nix build.
#
# Setup:
#   1. Open https://github.com/denialwm/denial/releases/tag/v0.2.6 > Assets,
#      copy the links of denial-*.pkg.tar.zst and denial-flutter-engine-*.pkg.tar.zst
#   2. Put them in `denialPkg` / `enginePkg` below.
#   3. Get hashes:  nix store prefetch-file --hash-type sha256 <url>
#   4. Import this file in hosts/surface/default.nix, rebuild, log out,
#      pick "Denial" in SDDM (Plasma stays the default).
#   5. If it misbehaves on the HD 620, set DENIA_FLUTTER_RENDERER=skia
#      (documented override for the Skia renderer).
{ config, lib, pkgs, ... }:

let
  fetchArch = { url, hash }: pkgs.fetchurl { inherit url hash; };

  denialPkg = fetchArch {
    url = "https://github.com/denialwm/denial/releases/download/v0.2.6/REPLACE-denial.pkg.tar.zst";
    hash = lib.fakeHash;
  };
  enginePkg = fetchArch {
    url = "https://github.com/denialwm/denial/releases/download/v0.2.6/REPLACE-denial-flutter-engine.pkg.tar.zst";
    hash = lib.fakeHash;
  };

  denial = pkgs.stdenv.mkDerivation {
    pname = "denial";
    version = "0.2.6";
    dontUnpack = true;

    nativeBuildInputs = [ pkgs.autoPatchelfHook pkgs.zstd pkgs.gnutar pkgs.makeWrapper ];
    buildInputs = with pkgs; [
      stdenv.cc.cc.lib systemd libseat libinput libxkbcommon libdrm libgbm
      libGL wayland fontconfig freetype zlib xwayland
    ];
    # Engine/shell libs are found via $out/lib at runtime.
    autoPatchelfIgnoreMissingDeps = [ "libflutter_engine.so" ];

    installPhase = ''
      mkdir -p $out extract
      for p in ${denialPkg} ${enginePkg}; do
        tar --zstd -xf $p -C extract --exclude='.PKGINFO' --exclude='.MTREE' \
            --exclude='.BUILDINFO' --exclude='.INSTALL'
      done
      cp -r extract/usr/* $out/
      [ -d extract/etc ] && cp -r extract/etc $out/etc || true

      # Rewrite hardcoded Arch paths (session file, units, scripts).
      grep -rIl '/usr/' $out | xargs -r sed -i "s|/usr/|$out/|g"

      # Xwayland + rtkit helpers on PATH.
      for b in $out/bin/*; do
        [ -x "$b" ] && wrapProgram "$b" --prefix PATH : ${lib.makeBinPath [ pkgs.xwayland ]} || true
      done
    '';

    passthru.providedSessions = [ "denial" ];  # must match share/wayland-sessions/denial.desktop
    meta = {
      description = "Flutter-native Wayland compositor (binary repackage)";
      license = lib.licenses.gpl3Plus;
      platforms = [ "x86_64-linux" ];
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    };
  };
in
{
  # Selectable in SDDM next to Plasma; defaultSession stays "plasma".
  services.displayManager.sessionPackages = [ denial ];
  environment.systemPackages = [ denial ];

  security.rtkit.enable = true;          # Denial's unprivileged priority fallback
  programs.xwayland.enable = true;
  hardware.graphics.enable = true;       # Intel HD 620 (Mesa)
  security.polkit.enable = true;

  # Surface: touch/pen come from linux-surface + iptsd (already imported via
  # nixos-hardware). Keep the user in `input` for libinput access (already set).
}
