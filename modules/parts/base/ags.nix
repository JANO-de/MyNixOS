{ self, inputs, ... }: {
  perSystem = { pkgs, system, lib, ... }: {
    # Definimos nuestro propio paquete de AGS con nuestra config integrada
    packages.myAgs = inputs.ags.lib.bundle {
      inherit pkgs;
      src = ./ags; # La carpeta donde estará tu JS/CSS
      name = "my-ags-shell";
      #entrypoint = "main.ts"; # o main.js

      # Aquí puedes añadir librerías extra si las necesitas
      extraPackages = with pkgs; [
        libdbusmenu-gtk3
        networkmanager
        brightnessctl
      ];
    };
  };
}