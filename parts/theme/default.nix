# Theme: Home Manager config for user jano (GTK, Qt), switched by modules.theme.enable.
# palette (plain data) is parts/theme/_palette.nix: lib.nix passes it to every module as `theme`.
# GTK/Qt colours, fonts and cursor come from Stylix (theme-stylix); the Home Manager part below
# only keeps the account basics and the icon theme.
_: {
  flake.nixosModules.theme =
    { config, lib, ... }:
    {
      options.modules.theme.enable = lib.mkEnableOption "Home Manager theming (GTK, Qt)";

      config = lib.mkIf config.modules.theme.enable {
        home-manager.users.jano =
          { pkgs, ... }:
          {
            home.username = "jano";
            home.homeDirectory = "/home/jano";
            home.stateVersion = "26.05";

            home.packages = [ pkgs.jq ];

            gtk = {
              enable = true;
              iconTheme = {
                name = "MacTahoe-dark";
                package = pkgs.callPackage ../../pkgs/mactahoe-icons.nix { };
              };
            };

            xdg.configFile."gtk-3.0/settings.ini".force = true;
            xdg.configFile."gtk-4.0/settings.ini".force = true;
          };
      };
    };
}
