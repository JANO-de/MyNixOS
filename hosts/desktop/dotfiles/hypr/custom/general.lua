-- >>> quickshell:managed:begin v1 - written by Settings -> Hyprland. Edits here are overwritten; put your own Lua above.
hl.config({ input = { kb_layout = "es" } })        --@k input:kb_layout
hl.config({ general = { layout = "scrolling" } })  --@k general:layout
hl.config({
    general = {
        layout = "scrolling",
    },
    scrolling = {
        column_width = 0.5,
        fullscreen_on_one_column = true,
        focus_fit_method = 1,
        follow_focus = true,
        explicit_column_widths = "0.333, 0.5, 0.667, 1.0",
    },
})
-- <<< quickshell:managed:end
