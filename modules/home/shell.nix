{ inputs, ... }: {
  imports = [ inputs.noctalia.homeModules.default ];

  programs.noctalia-shell = {
    enable = true;
    # Noctalia settings are declarative
    settings = {
      bar.position = "top";
      # You can explore more settings in the Noctalia documentation
    };
  };
}
