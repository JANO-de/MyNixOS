{ self, inputs, ... }: {
  # Definimos el módulo de Plymouth
  flake.nixosModules.ply = { pkgs, config, lib, ... }: 
    let
      # El "let" va ANTES de abrir el set de configuración final
      hunt-showdown-plymouth = pkgs.stdenv.mkDerivation {
        pname = "hunt-showdown-plymouth";
        version = "1.0";

        src = pkgs.fetchFromGitHub {
          owner = "Anxhul10";
          repo = "huntShowdown-plymouth";
          rev = "master";
          sha256 = "sha256-zBaz6LWan6ExXfWv5nRGjamfV47SpfQSxvS/jQ8G4Ck="; 
        };

        dontPatchELF = true;
        dontRewriteMode = true;

        installPhase = ''
          mkdir -p $out/share/plymouth/themes/huntShowdown-plymouth
          cp -r * $out/share/plymouth/themes/huntShowdown-plymouth
          
          # Ajustamos las rutas eliminando cualquier referencia absoluta a /usr
          find $out -type f -name "*.plymouth" -exec sed -i "s|/usr/share/plymouth/themes/huntShowdown-plymouth|$out/share/plymouth/themes/huntShowdown-plymouth|g" {} +
          find $out -type f -name "*.script" -exec sed -i "s|/usr/share/plymouth/themes/huntShowdown-plymouth|$out/share/plymouth/themes/huntShowdown-plymouth|g" {} +
        '';
      };
    in
    {
      # Aquí empieza la configuración real de NixOS
      boot.plymouth = {
        enable = true;
        themePackages = [ hunt-showdown-plymouth ];
        theme = "huntShowdown-plymouth";
      };

      # Configuraciones para NVIDIA
      boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
      boot.kernelParams = [ "quiet" "splash" "nvidia-drm.modeset=1" ];
    };
}