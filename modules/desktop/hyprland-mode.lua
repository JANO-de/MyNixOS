-- Step 3: tablet / desktop mode switch.
-- Installed to /etc/hypr/hyprland-mode.lua and included from hyprland.lua with:
--   dofile("/etc/hypr/hyprland-mode.lua")
-- Manual use:  hyprctl eval 'set_mode("tablet")'   |   hyprctl eval 'set_mode("desktop")'
-- State file (read by the shell): $XDG_RUNTIME_DIR/hypr-mode  ("tablet" or "desktop")

local default_mode = "desktop" -- mode at first login (no state file yet)

local rt = (os and os.getenv and os.getenv("XDG_RUNTIME_DIR")) or "/run/user/1000"
local state_path = rt .. "/hypr-mode"

local function read_state()
  local ok, f = pcall(io.open, state_path, "r")
  if not ok or not f then return nil end
  local s = f:read("*l")
  f:close()
  if s == "tablet" or s == "desktop" then return s end
  return nil
end

-- A config reload re-runs this file, so restore the last mode instead of the default.
local mode = read_state() or default_mode

-- Look per mode. Each key is in its own pcall: a wrong key only loses that line.
local function apply_look(m)
  if m == "tablet" then
    pcall(hl.config, { general = { gaps_in = 6, gaps_out = 6, border_size = 0 } })
    pcall(hl.config, { decoration = { rounding = 20 } })
    pcall(hl.config, { general = { layout = "monocle" } }) -- one app per screen (unverified name)
  else
    pcall(hl.config, { general = { gaps_in = 5, gaps_out = 10, border_size = 2 } })
    pcall(hl.config, { decoration = { rounding = 12 } })
    pcall(hl.config, { general = { layout = "dwindle" } })
  end
end

-- Apply the look at parse time so reloads keep it.
apply_look(mode)

function set_mode(m)
  if m ~= "tablet" and m ~= "desktop" then return end
  mode = m
  apply_look(m)
  hl.exec_cmd("echo " .. m .. " > " .. state_path)
  if m == "tablet" then
    hl.exec_cmd("systemctl --user start surface-rotate")
  else
    hl.exec_cmd("systemctl --user stop surface-rotate")
    hl.exec_cmd("surface-rotate 0")
    hl.exec_cmd("pkill -x wvkbd-mobintl; echo hidden > " .. rt .. "/kbd-visible")
  end
  pcall(hl.notification.create, { text = "Mode: " .. m, timeout = 1500, icon = "ok" })
end

-- Manual toggle (keyboard now, shell button later).
hl.bind("SUPER + SHIFT + T", function()
  set_mode(mode == "tablet" and "desktop" or "tablet")
end)

-- DeX-like switch: external monitor plugged in -> desktop, unplugged -> tablet.
local function is_internal(name)
  return name ~= nil and name:match("^eDP") ~= nil
end

hl.on("monitor.added", function(m)
  if m and not is_internal(m.name) then set_mode("desktop") end
end)

hl.on("monitor.removed", function(m)
  if m and not is_internal(m.name) then set_mode("tablet") end
end)

-- Apply side effects (service, state file) once at session start.
hl.on("hyprland.start", function()
  set_mode(mode)
end)

-- Halo: blur behind the glass dock (namespace set in components/Dock.qml)
hl.layer_rule({ match = { namespace = "halo-dock" }, blur = true, ignore_alpha = 0 })

-- Halo: SUPER+A toggles the home screen, and it gets the same blur as the dock
hl.bind("SUPER + A", hl.dsp.exec_cmd("halo-ctl call home toggle"))
hl.layer_rule({ match = { namespace = "halo-home" }, blur = true, ignore_alpha = 0 })

-- Halo shade + control center: blur, SUPER+N toggle.
hl.layer_rule({ match = { namespace = "halo-shade" }, blur = true, ignore_alpha = 0 })
hl.bind("SUPER + N", hl.dsp.exec_cmd("halo-ctl call shade toggle"))

-- Keyboard fallback (the 2-finger edge swipe is unverified).
hl.bind("SUPER + K", hl.dsp.exec_cmd("kbd-toggle"))
