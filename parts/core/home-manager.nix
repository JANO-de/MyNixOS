# Home Manager wiring (per-user config comes from parts/theme).
_: {
  flake.nixosModules.core-home-manager =
    { inputs, theme, ... }:

    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = null;
        extraSpecialArgs = { inherit inputs theme; };
      };
    };
}
