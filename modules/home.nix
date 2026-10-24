# Home Manager config for user jano (shared by every host): GTK/Qt theme from
# theme.nix and the alacritty config. Compositor configs live next to their
# NixOS modules (desktop/mango.nix, desktop/niri.nix, desktop/shell/*).
{ pkgs, lib, theme, ... }:

let
  c = theme.palette;

  # Catppuccin GTK theme from nixpkgs
  gtkPkg = pkgs.catppuccin-gtk.override {
    variant = "mocha";
    accents = [ "mauve" ];
    size = "standard";
    tweaks = [ "black" ];
  };

  # Kvantum theme (Qt apps) from nixpkgs
  kvantumPkg = pkgs.catppuccin-kvantum.override {
    variant = "mocha";
    accent = "mauve";
  };

  # colors.css for GTK — same variables home-manager writes, so the theme
  # (catppuccin-gtk) and gtk.css agree with each other.
  colorsCss = lib.concatStringsSep "\n" (lib.mapAttrsToList
    (name: value: "@define-color ${name} ${value};")
    {
      bg = c.base;
      bg_alt = c.mantle;
      surface = c.surface0;
      surface_alt = c.surface1;
      fg = c.text;
      fg_muted = c.subtext1;
      fg_subtle = c.overlay1;
      accent = c.mauve;
      accent_alt = c.lavender;
      error = c.red;
      success = c.green;
      warning = c.yellow;
    });
in
{
  home.username = "jano";
  home.homeDirectory = "/home/jano";
  home.stateVersion = "26.05";

  home.packages = [ pkgs.jq ];

  # Deploy alacritty config to ~/.config/alacritty/alacritty.toml as a real
  # writable file (via activation, not a store symlink) because:
  #
  #   1. Shape: [general] with the colors.toml import FIRST and no hardcoded
  #      [colors], so terminal colors can live in ~/.config/alacritty/
  #      colors.toml. The import must precede color definitions to win
  #      (alacritty loads imports first, main file last).
  #   2. Writable: a writable file lets external tools touch it to trigger
  #      alacritty's live config reload; that would fail against a read-only
  #      store symlink.
  #
  # The file is rewritten on every home-manager activation, overriding any
  # manual edits.
  home.activation.alacrittyConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/.config/alacritty"
    # Drop any previous store symlink (read-only target) before writing.
    run rm -f "$HOME/.config/alacritty/alacritty.toml"
    run cat > "$HOME/.config/alacritty/alacritty.toml" <<'EOF'
    [general]
    import = ["~/.config/alacritty/colors.toml"]

    [env]
    TERM = "alacritty"

    [window]
    decorations = "None"
    opacity = 0.93
    startup_mode = "Maximized"

    [font]
    normal = { family = "${theme.fonts.terminal}", style = "Regular" }
    bold = { family = "${theme.fonts.terminal}", style = "Bold" }
    italic = { family = "${theme.fonts.terminal}", style = "Italic" }
    bold_italic = { family = "${theme.fonts.terminal}", style = "Bold Italic" }
    size = 11.0

    [cursor]
    style = { shape = "Block", blinking = "Always" }

    [hints]
    enabled = [{ regex = "(ipfs|ipns|magnet|mailto|gemini|gopher|https|http|news|file|git|ssh|ftp)://[^\\s]+", command = "xdg-open", post_processing = true, persist = false }]
    EOF
  '';

  gtk = {
    enable = true;
    theme = {
      name = "catppuccin-mocha-mauve-standard+black";
      package = gtkPkg;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    font = {
      name = theme.fonts.sans;
      package = pkgs.inter;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk3";
    kvantum = {
      enable = true;
      settings.General.theme = "catppuccin-mocha-mauve";
      themes = [ kvantumPkg ];
    };
  };

  # Keep the manual gtk.css/colors.css declarative and in sync with the theme
  xdg.configFile."gtk-3.0/colors.css".text = colorsCss;
  xdg.configFile."gtk-3.0/gtk.css".text = "@import 'colors.css';\n";

  # The gtk module writes settings.ini as a regular file, so every activation
  # sees a "foreign" file it wants to back up — and the previous run's
  # settings.ini.backup blocks it, failing the whole switch. Force overwrite.
  xdg.configFile."gtk-3.0/settings.ini".force = true;
  xdg.configFile."gtk-4.0/settings.ini".force = true;
}
