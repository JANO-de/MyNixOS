{ theme, lib, ... }:

{
  # Deploy alacritty config to ~/.config/alacritty/alacritty.toml as a real
  # writable file (via activation, not a store symlink) because:
  #
  #   1. Shape: [general] with the colors.toml import FIRST and no hardcoded
  #      [colors] — this is exactly what inir's wallpaper theming considers
  #      "already correct", so it owns terminal colors via colors.toml and
  #      leaves this file alone. The import must precede color definitions to
  #      win (alacritty loads imports first, main file last).
  #   2. Writable: inir's reload step touches this file to trigger alacritty's
  #      live config reload; that would fail against a read-only store symlink.
  #
  # The file is rewritten on every home-manager activation, overriding any
  # manual edits (inir itself doesn't rewrite it once it's "already correct").
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
}