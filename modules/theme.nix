# Central theme definition for the whole system.
# A single source of truth — every module reads its colors/fonts from here,
# so changing `current` restyles niri, terminals, GTK, Qt, SDDM...
let
  # Available schemes
  schemes = {
    catppuccin-mocha = {
      name = "catppuccin-mocha";

      # Catppuccin mocha palette (as used by the system24 Discord theme)
      palette = {
        base = "#1e1e2e";       # main background
        mantle = "#181825";     # secondary background
        crust = "#11111b";      # deepest background

        surface0 = "#313244";   # cards, hover, buttons
        surface1 = "#45475a";   # borders, clicked
        surface2 = "#585b70";   # muted elements

        overlay0 = "#6c7086";
        overlay1 = "#7f849c";
        overlay2 = "#9399b2";

        subtext0 = "#a6adc8";
        subtext1 = "#bac2de";
        text = "#cdd6f4";       # main foreground

        lavender = "#b4befe";
        blue = "#89b4fa";
        sapphire = "#74c7ec";
        sky = "#89dceb";
        teal = "#94e2d5";
        green = "#a6e3a1";
        yellow = "#f9e2af";
        peach = "#fab387";
        maroon = "#eba0ac";
        red = "#f38ba8";
        mauve = "#cba6f7";      # accent (system24 purple)
        pink = "#f5c2e7";
        flamingo = "#f2cdcd";
        rosewater = "#f5e0dc";
      };

      # Semantic aliases used by individual apps
      ui = {
        bg = "base";
        bgAlt = "mantle";
        bgDeep = "crust";
        surface = "surface0";
        surfaceAlt = "surface1";
        text = "text";
        textMuted = "subtext1";
        textSubtle = "overlay1";
        accent = "mauve";
        accentAlt = "lavender";
        error = "red";
        ok = "green";
        warn = "yellow";
        border = "surface1";
      };

      fonts = {
        sans = "Inter";
        serif = "Lora";
        mono = "DM Mono";
        terminal = "JetBrainsMono Nerd Font"; # nerd glyphs needed by starship
      };
    };
  };

  # Theme currently in use. Swap this name to restyle the whole system.
  current = "catppuccin-mocha";
  scheme = schemes.${current};
in
scheme
// {
  inherit schemes current;

  # Resolve a ui alias (or raw palette key) to its hex color.
  # e.g. theme.color "bg" -> "#1e1e2e"
  color = key: scheme.palette.${scheme.ui.${key} or key};
}
