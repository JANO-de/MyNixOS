{ config, pkgs, theme, ... }:

let
  c = theme.palette;
in
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
    decorations = "None"
    opacity = 0.93
    startup_mode = "Maximized"

    [font]
    normal = { family = "${theme.fonts.terminal}", style = "Regular" }
    bold = { family = "${theme.fonts.terminal}", style = "Bold" }
    italic = { family = "${theme.fonts.terminal}", style = "Italic" }
    bold_italic = { family = "${theme.fonts.terminal}", style = "Bold Italic" }
    size = 11.0

    [colors]
    primary = { background = "${c.base}", foreground = "${c.text}" }
    cursor = { text = "${c.base}", cursor = "${c.rosewater}" }
    selection = { text = "${c.base}", background = "${c.surface2}" }

    normal = { black = "${c.surface1}", red = "${c.red}", green = "${c.green}", yellow = "${c.yellow}", blue = "${c.blue}", magenta = "${c.pink}", cyan = "${c.teal}", white = "${c.subtext1}" }
    bright = { black = "${c.surface2}", red = "${c.red}", green = "${c.green}", yellow = "${c.yellow}", blue = "${c.blue}", magenta = "${c.pink}", cyan = "${c.teal}", white = "${c.subtext0}" }

    [cursor]
    style = { shape = "Block", blinking = "Always" }

    [hints]
    enabled = [{ regex = "(ipfs|ipns|magnet|mailto|gemini|gopher|https|http|news|file|git|ssh|ftp)://[^\\s]+", command = "xdg-open", post_processing = true, persist = false }]
  '';

  environment.sessionVariables.ALACRITTY_CONFIG = "/etc/alacritty/alacritty.toml";
}
