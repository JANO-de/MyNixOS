{ ... }:
{
  flake.nixosModules.programs-ytm-rs =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.ytm-rs;
      src = builtins.fetchGit {
        url = "https://github.com/grapedjuice/ytm-rs";
        rev = "c661d77a7bddf63493e2b18e912e2d6d4fb6af95";
      };
      libs = with pkgs; [
        vulkan-loader
        libGL
        wayland
        libxkbcommon
        xorg.libX11
        xorg.libXcursor
        xorg.libXi
        xorg.libXrandr
        libayatana-appindicator
      ];
      pkg = pkgs.rustPlatform.buildRustPackage {
        pname = "ytm-rs";
        version = "0.3.1";
        inherit src;
        cargoLock.lockFile = "${src}/Cargo.lock";
        nativeBuildInputs = with pkgs; [
          pkg-config
          nasm
          makeWrapper
          rustPlatform.bindgenHook
        ];
        buildInputs = with pkgs; [
          glib-networking
          openssl
          alsa-lib
          gtk3
          webkitgtk_4_1
          xdotool
          dbus
          libayatana-appindicator
        ];
        doCheck = false;
        postInstall = ''
          install -Dm644 linux/ytm-rs.desktop $out/share/applications/ytm-rs.desktop
          install -Dm644 assets/icon/icon.png $out/share/icons/hicolor/256x256/apps/ytm-rs.png
          wrapProgram $out/bin/ytm-rs \
            --set GIO_EXTRA_MODULES ${pkgs.glib-networking}/lib/gio/modules \
            --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath libs} \
            --prefix PATH : ${
              lib.makeBinPath [
                pkgs.yt-dlp
                pkgs.nodejs
              ]
            }
        '';
        meta.mainProgram = "ytm-rs";
      };
    in
    {
      options.programs.ytm-rs.enable = lib.mkEnableOption "ytm-rs (native YouTube Music)";
      config = lib.mkIf cfg.enable { environment.systemPackages = [ pkg ]; };
    };
}
