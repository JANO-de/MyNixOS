{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    alacritty
    starship
    eza
    bat
    ripgrep
    fd
    procs
    zoxide
    z-lua
    fastfetch
  ];

  environment.etc."alacritty/alacritty.toml".text = ''
    [env]
    TERM = "alacritty"

    [window]
    decorations = "Full"
    opacity = 0.93
    startup_mode = "Maximized"

    [font]
    normal = { family = "JetBrainsMono Nerd Font", style = "Regular" }
    bold = { family = "JetBrainsMono Nerd Font", style = "Bold" }
    italic = { family = "JetBrainsMono Nerd Font", style = "Italic" }
    bold_italic = { family = "JetBrainsMono Nerd Font", style = "Bold Italic" }
    size = 11.0

    [colors]
    primary = { background = "#1e1e2e", foreground = "#cdd6f4" }
    cursor = { text = "#1e1e2e", cursor = "#f5e0dc" }
    selection = { text = "#1e1e2e", background = "#f5e0dc" }

    normal = { black = "#45475a", red = "#f38ba8", green = "#a6e3a1", yellow = "#f9e2af", blue = "#89b4fa", magenta = "#f5c2e7", cyan = "#94e2d5", white = "#bac2de" }
    bright = { black = "#585b70", red = "#f38ba8", green = "#a6e3a1", yellow = "#f9e2af", blue = "#89b4fa", magenta = "#f5c2e7", cyan = "#94e2d5", white = "#a6adc8" }

    [cursor]
    style = { shape = "Block", blinking = "Always" }

    [hints]
    enabled = [{ regex = "(ipfs|ipns|magnet|mailto|gemini|gopher|https|http|news|file|git|ssh|ftp)://[^\\s]+", command = "xdg-open", post_processing = true, persist = false }]
  '';

  environment.sessionVariables.ALACRITTY_CONFIG = "/etc/alacritty/alacritty.toml";
}
