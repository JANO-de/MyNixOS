# DAM (Desarrollo de Aplicaciones Multiplataforma) toolkit, sized for the
# 8GB RAM / 128GB Surface: no Android Studio, IntelliJ or Eclipse (several GB
# each; use the desktop/laptop for those). VS Code covers Java, Kotlin, web, SQL.
{ pkgs, ... }:

{
  programs.java = {
    enable = true; # sets JAVA_HOME
    package = pkgs.jdk21;
  };

  environment.systemPackages = with pkgs; [
    vscode        # IDE (unfree, allowed in modules/core/nix.nix)
    maven
    gradle
    nodejs_22
    dbeaver-bin   # SQL client (MySQL, PostgreSQL, SQLite, ...)
    sqlitebrowser # quick SQLite inspection
    drawio        # UML / ER diagrams
  ];
}
