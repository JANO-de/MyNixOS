{ self, inputs, ... }: {
  flake.nixosModules.ply = { pkgs, config, lib, ... }: {
    let
    # Definimos el tema de Hunt Showdown
    hunt-showdown-plymouth = pkgs.stdenv.mkDerivation {
        pname = "hunt-showdown-plymouth";
        version = "1.0";

        src = pkgs.fetchFromGitHub {
        owner = "Anxhul10";
        repo = "huntShowdown-plymouth";
        rev = "master"; # O el hash específico si prefieres
        sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Pon un hash falso primero, Nix te dará el correcto
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
      boot.plymouth = {
        enable = true;
        themePackages = [ hunt-showdown-plymouth ];
        theme = "hunt";
      };

      # IMPORTANTE: Para NVIDIA y Plymouth      
      boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
      boot.kernelParams = [ "quiet" "splash" "nvidia-drm.modeset=1" ];
    };
  };
}