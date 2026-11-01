-- This file will not be overwritten across dots-hyprland updates.
-- The file name is for the sake of organization and does not matter
-- See the corresponding files in ~/.config/hypr/hyprland for examples

-- >>> quickshell:managed:begin v1 - written by Settings -> Hyprland. Edits here are overwritten; put your own Lua above.
pcall(hl.unbind, "SUPER + Space")                                               --@u SUPER+space
hl.bind("SUPER + Space", hl.dsp.global("quickshell:searchToggleRelease"), { description = "Shell: Toggle search" })  --@b SUPER+space
pcall(hl.unbind, "SUPER + SUPER_L")                                             --@u SUPER+super_l
-- <<< quickshell:managed:end
