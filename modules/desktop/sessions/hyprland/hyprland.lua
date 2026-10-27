-- Hyprland baseline (step 1). Template: hyprland.nix fills the @PLACEHOLDERS@.
-- Binds come FIRST and look/input are wrapped in pcall, so a wrong option name
-- can never leave the session without keybinds. Check errors: hyprctl configerrors
-- Docs: https://wiki.hypr.land (Lua API: hl.bind, hl.dsp.*, hl.config, hl.on)

local mod = "SUPER"

-- ---- binds ------------------------------------------------------------------
hl.bind(mod .. " + Return", hl.dsp.exec_cmd("alacritty"))
hl.bind(mod .. " + E", hl.dsp.exec_cmd("alacritty -e yazi"))
hl.bind(mod .. " + B", hl.dsp.exec_cmd("zen"))
hl.bind(mod .. " + W", hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + E", hl.dsp.exit())
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mod .. " + CTRL + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind("Print", hl.dsp.exec_cmd("@SCREENSHOT@"))

for _, d in ipairs({ "left", "right", "up", "down" }) do
  hl.bind(mod .. " + " .. d, hl.dsp.focus({ direction = d }))
  hl.bind(mod .. " + CTRL + " .. d, hl.dsp.window.move({ direction = d }))
end

for i = 1, 9 do
  hl.bind(mod .. " + " .. i, hl.dsp.focus({ workspace = i }))
  hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- media keys (also on the lock screen)
local wpctl = "@WPCTL@"
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(wpctl .. " set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(wpctl .. " set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(wpctl .. " set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -q set 5%+"), { locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -q set 5%-"), { locked = true })

-- dynisland (shell) binds
@SHELL_BINDS@

-- ---- environment ------------------------------------------------------------
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("QT_IMAGEIO_MAXALLOC", "0")

-- ---- autostart (dynisland itself is a systemd user service) -----------------
hl.on("hyprland.start", function()
  hl.exec_cmd("@POLKIT@")
  hl.exec_cmd("wl-clip-persist --clipboard regular --reconnect-tries 0")
end)

-- ---- input + look (each in its own pcall: a bad key only loses that block) ---
pcall(hl.config, {
  input = {
    kb_layout = "es",
    kb_variant = "nodeadkeys",
    kb_options = "compose:rctrl",
    repeat_rate = 25,
    repeat_delay = 600,
    touchpad = { natural_scroll = true },
  },
})

pcall(hl.config, {
  general = { gaps_in = 5, gaps_out = 10, border_size = 2 },
  decoration = { rounding = 12 },
})

-- border colors from theme.nix (key layout may differ between versions)
pcall(hl.config, {
  general = { col = { active_border = "@ACCENT@", inactive_border = "@SURFACE@" } },
})

pcall(hl.config, {
  misc = { disable_hyprland_logo = true, disable_splash_rendering = true },
})

@SESSION_EXTRAS@
dofile("/etc/hypr/hyprland-mode.lua")