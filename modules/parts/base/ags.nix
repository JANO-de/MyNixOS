{ inputs, ... }: {
  perSystem = { pkgs, system, ... }: {
    # Usamos el builder específico para tu sistema (x86_64-linux)
    packages.myAgs = inputs.ags.builders.${system}.bundle {
      inherit pkgs;
      src = ./ags; # Asegúrate de que esta carpeta tenga tu main.ts o config.js
      name = "my-ags-shell";
      entrypoint = "main.ts";

      extraPackages = with pkgs; [
        libdbusmenu-gtk3
        networkmanager
        brightnessctl
      ];
    };
  };

  # Módulo de NixOS para instalar el binario y AGS base
  flake.nixosModules.ags = { pkgs, ... }: {
    environment.systemPackages = [
      inputs.ags.packages.${pkgs.system}.default
    ];
  };
}