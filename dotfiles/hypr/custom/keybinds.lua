-- User Keybindings
hl.bind("CTRL + SUPER + Slash", hl.dsp.exec_cmd("xdg-open ~/.config/illogical-impulse/config.json"), { description = "Edit shell config" })

-- >>> quickshell:managed:begin v1 - written by Settings -> Hyprland. Edits here are overwritten; put your own Lua above.
pcall(hl.unbind, "SUPER + Comma")                                               --@u SUPER+comma
hl.bind("SUPER + Comma", hl.dsp.exec_cmd("hyprctl switchxkblayout all next"), { description = "Switch keyboard layout" })  --@b SUPER+comma
pcall(hl.unbind, "SUPER + Space")                                               --@u SUPER+space
hl.bind("SUPER + Space", hl.dsp.global("quickshell:searchToggleRelease"), { description = "Shell: Toggle search" })  --@b SUPER+space
pcall(hl.unbind, "SUPER + SUPER_L")                                             --@u SUPER+super_l
-- <<< quickshell:managed:end
