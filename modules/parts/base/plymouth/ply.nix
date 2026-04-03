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
          sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; 
        };

        installPhase = ''
          mkdir -p $out/share/plymouth/themes/hunt
          cp -r * $out/share/plymouth/themes/hunt
          # Corregimos la ruta interna del archivo .plymouth
          sed -i "s|ImageDir=/usr/share/plymouth/themes/hunt|ImageDir=$out/share/plymouth/themes/hunt|g" $out/share/plymouth/themes/hunt/hunt.plymouth
          sed -i "s|ScriptFile=/usr/share/plymouth/themes/hunt/hunt.script|ScriptFile=$out/share/plymouth/themes/hunt/hunt.script|g" $out/share/plymouth/themes/hunt/hunt.plymouth
        '';
      };
    in
    {
      # Aquí empieza la configuración real de NixOS
      boot.plymouth = {
        enable = true;
        themePackages = [ hunt-showdown-plymouth ];
        theme = "hunt";
      };

      # Configuraciones para NVIDIA
      boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
      boot.kernelParams = [ "quiet" "splash" "nvidia-drm.modeset=1" ];
    };
}