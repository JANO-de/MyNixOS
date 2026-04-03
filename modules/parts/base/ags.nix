{ inputs, lib, ... }: {
  perSystem = { pkgs, system, lib, ... }: {
    # Usamos la librería directamente desde el paquete de ags para el sistema actual
    packages.myAgs = inputs.ags.lib.bundle {
      inherit pkgs;
      src = ./ags; # Asegúrate de que esta carpeta existe y tiene un config.js o main.ts
      name = "my-ags-shell";
      entrypoint = "main.ts"; # Descomenta y asegúrate de que el nombre coincida

      extraPackages = with pkgs; [
        libdbusmenu-gtk3
        networkmanager
        brightnessctl
      ];
    };
  };

  # Esto registra el módulo para que puedas usarlo en tu configuración de NixOS
  flake.nixosModules.ags = { pkgs, ... }: {
    environment.systemPackages = [
      inputs.ags.packages.${pkgs.system}.default
    ];
  };
}