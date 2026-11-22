# Java development: IDEs, JDK and build tools.
_: {
  flake.nixosModules.dev-java =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.modules.dev.java;
    in
    {
      options.modules.dev.java = lib.mkEnableOption "Java development tools (IDEs, JDK, Maven, Gradle)";

      config = lib.mkIf cfg {
        environment.systemPackages = with pkgs; [
          eclipses.eclipse-java
          jetbrains.idea
          netbeans
          jdk25
          maven
          gradle
        ];
      };
    };
}
