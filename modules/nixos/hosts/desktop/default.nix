{ self, inputs, ... }: {
  flake.nixosConfigurations.myMachine = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.desktopConfiguration
      self.nixosModules.core
      self.nixosModules.basicApps
    ];
  };
}