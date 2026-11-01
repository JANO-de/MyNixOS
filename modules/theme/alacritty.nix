# Alacritty config deployment for user jano.
{
  pkgs,
  lib,
  theme,
  ...
}:

{
  home.activation.alacrittyConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/.config/alacritty"
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
}
