{ self, inputs, ... }: {
  flake.nixosConfigurations.desktop = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.desktopConfiguration
      self.nixosModules.core
      self.nixosModules.basicApps
    ];
  };
}