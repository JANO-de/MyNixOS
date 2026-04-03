{ inputs, pkgs, ... }: {
  flake.nixosModules.ags = { pkgs, ... }: {
    imports = [ inputs.ags.nixosModules.default ];

    programs.ags = {
      enable = true;
      # Paquetes adicionales que AGS podría necesitar para tus snippets
      extraPackages = with pkgs; [
        gtksourceview
        webkitgtk
        accountsservice
      ];
    };

    # Instalamos dependencias para que tus scripts de JS funcionen
    environment.systemPackages = with pkgs; [
      bun # Recomendado para ejecutar/probar JS rápido
      dart-sass # Si quieres usar SCSS para los estilos de tus menús
    ];
  };
}

/*{ self, inputs, ... }: {
  perSystem = { pkgs, ... }: {
    packages.myNoctalia = inputs.wrapper-modules.wrappers.noctalia-shell.wrap {
      inherit pkgs; # THIS PART IS VERY IMPORTAINT, I FORGOT IT IN THE VIDEO!!!*/