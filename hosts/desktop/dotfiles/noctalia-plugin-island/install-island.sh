#!/usr/bin/env bash
# install-island.sh — writes the jano/island Noctalia plugin into BOTH hosts'
# dotfiles from one embedded source of truth, then prints the verify command.
#
# Usage:  ./install-island.sh [FLAKE_REPO_ROOT]     (default: current directory)
# The island files are identical on desktop and laptop by design.
set -euo pipefail
ROOT="${1:-.}"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

mkdir -p "$STAGE/noctalia-plugin-island"

cat > "$STAGE/noctalia-plugin-island/island.luau" <<'ISLAND_LUA_EOF'
--!nonstrict
-- jano/island v0.2.0 — blurred pill island for niri + Noctalia v5.4.1 (plugin_api 51)
-- Palette (hard-coded): #17181A @ ~70% over niri blur, accent #FF5A1F, silver #C9CED4.
-- Type: JetBrains Mono. Motion: spring on the surface size via noctalia.layer.configure;
-- frame ticks only while springing, while the equalizer shows, or during a pomo pulse.
--
-- UNVERIFIED (adjust to taste if a control renders oddly):
--   * Tabler glyph names (player-play-filled, volume-2, circle-dot, chevron-up, ...)
--   * font family "JetBrains Mono" — the nerd-font package may register as
--     "JetBrainsMono Nerd Font"; labels fall back to the host default if missing.
--   * file:// artUrl percent-encoding is not decoded (host-side %20 stays literal).
-- Build errors go to noctalia.log and fall back to a clock-only pill.

local ACC, SIL, TXT = "#FF5A1F", "#C9CED4", "#F2F4F7"
local EDGE, PILL, CARD = "#C9CED433", "#17181AB3", "#00000066"
local FONT = "JetBrains Mono"
local FOC_MS, BRK_MS = 25 * 60000, 5 * 60000
local POP_MS, FULL_MS, WX_MS = 1800, 10000, 15 * 60000

local D = { vol = nil, mute = false, mic = false, bri = nil, bat = nil, chg = false,
            batFull = false, lowArm = false, ws = nil, cam = false, rec = false }
local open, fullExp = false, 0
local pop = { what = "", val = "", exp = 0 }
local swr, swacc, swt0 = false, 0, 0
local por, pleft, ptotal, pphase, ppulse = false, FOC_MS, FOC_MS, "focus", 0
local W, H, vw, vh, tw, th, lw, lh = 200, 44, 0, 0, 200, 44, 200, 44
local fade, shown, dirty, ticking = 1, "", true, false
local lastMin, lastUp, pollAt, wxAt = noctalia.formatTime("%H:%M"), nil, 0, 0
local art = { url = "", path = "", ok = false }
local wx = { s = "", t = 0 }
local evId = ""
local FALLBACK = false

local function now() return noctalia.nowMs() end
local function log(m) noctalia.log("island: " .. tostring(m)) end
local function run(c) noctalia.runAsync(c) end
local function clamp(x, a, b) return math.max(a, math.min(b, x or a)) end
local function fmt(ms)
  local s = math.max(0, math.floor((ms or 0) / 1000))
  return string.format("%d:%02d", math.floor(s / 60), s % 60)
end
local function mix(a, b, t)
  local f = function(c1, c2) return math.floor(c1 + (c2 - c1) * t + 0.5) end
  return string.format("#%02x%02x%02x",
    f(tonumber(a:sub(2, 3), 16), tonumber(b:sub(2, 3), 16)),
    f(tonumber(a:sub(4, 5), 16), tonumber(b:sub(4, 5), 16)),
    f(tonumber(a:sub(6, 7), 16), tonumber(b:sub(6, 7), 16)))
end
local function edgeColor(n) -- completion pulse: silver edge swings to orange and back
  if n < ppulse then
    local t = 1 - (ppulse - n) / 1400
    if t >= 0 and t <= 1 then return mix(SIL, ACC, math.abs(math.sin(math.pi * t))) .. "88" end
  end
  return EDGE
end
local function lab(text, size, color, maxW)
  local p = { text = tostring(text or ""), fontSize = size or 12, color = color or SIL,
              fontWeight = "bold", fontFamily = FONT, maxLines = 1 }
  if maxW then p.maxWidth = maxW end
  return ui.label(p)
end
local function gly(name, size, color)
  return ui.glyph({ name = name, size = size or 14, color = color or SIL })
end
local function ghost(g, fn, size)
  return ui.row({ width = 30, height = 30, radius = 15, align = "center", justify = "center", onClick = fn },
                { gly(g, size or 15, SIL) })
end
local function bar(frac, wd, hg, fillc, trackc)
  return ui.progress({ progress = clamp(frac, 0, 1), width = wd, height = hg or 4,
                       fill = fillc or ACC, track = trackc or "#C9CED422", radius = (hg or 4) / 2 })
end
local function eq(n)
  local b = {}
  for i = 1, 4 do
    b[i] = ui.box({ fill = ACC, width = 3, radius = 1, height = 4 + 10 * math.abs(math.sin(n / 180 + i * 1.15)) })
  end
  return ui.row({ gap = 2, align = "center" }, b)
end
local buildFn, render, tick -- forward declarations: flush() re-renders immediately
local function popEv(what, val, ms)
  pop = { what = what, val = val, exp = now() + (ms or POP_MS) }
  dirty = true
end
local function flush() -- re-render NOW (click handlers); data callbacks just set dirty
  dirty = true
  render()
  tick()
end

-- One polled shell bundle (2 s): sink, mic, brightness, battery, workspace, camera, recorder.
local CMD = [[
wpctl get-volume @DEFAULT_AUDIO_SINK@
echo ---
wpctl get-volume @DEFAULT_AUDIO_SOURCE@
echo ---
brightnessctl -m
echo ---
cat /sys/class/power_supply/BAT*/capacity /sys/class/power_supply/BAT*/status 2>/dev/null
echo ---
niri msg -j workspaces 2>/dev/null | jq -r '.[]|select(.is_focused or .focused)|.idx' 2>/dev/null
echo ---
fuser /dev/video0 2>/dev/null
echo ---
pgrep -f 'wf-recorder|gpu-screen-recorder|obs' >/dev/null && echo REC
]]

local function poll()
  noctalia.runAsync(CMD, function(r)
    local a, i, out = {}, 1, (r.stdout or "") .. "\n---\n"
    for part in out:gmatch("(.-)\n%-%-%-\n") do a[i] = part i = i + 1 end
    local sink, src = a[1] or "", a[2] or ""
    local vol = tonumber(sink:match("Volume: ([%d%.]+)"))
    local mute = sink:find("MUTED") ~= nil
    local mic = src:find("MUTED") ~= nil
    local bri = tonumber((a[3] or ""):match(",(%d+)%%,"))
    local bat = tonumber((a[4] or ""):match("^(%d+)"))
    local chg = (a[4] or ""):find("Charging") ~= nil
    local full = (a[4] or ""):find("Full") ~= nil
    local ws = (a[5] or ""):match("%d+")
    local cam, rec = (a[6] or "") ~= "", (a[7] or "") ~= ""
    if D.vol ~= nil then -- first read seeds state, only deltas pop
      if vol and (math.abs(vol - D.vol) > 0.005 or mute ~= D.mute) then popEv(mute and "mute" or "vol", vol) end
      if bri and D.bri and bri ~= D.bri then popEv("bri", bri / 100) end
      if mic ~= D.mic then popEv(mic and "micm" or "mic", 1) end
      if cam and not D.cam then popEv("cam", 1) end
      if rec and not D.rec then popEv("rec", 1) end
      if bat and D.bat then
        if bat <= 15 and not chg and not D.lowArm then popEv("lowbat", bat, 2600) D.lowArm = true end
        if bat > 20 or chg then D.lowArm = false end
        if full and not D.batFull and not chg then popEv("charged", bat, 2600) end
      end
    end
    D.vol, D.mute, D.mic, D.bri, D.bat, D.chg, D.batFull, D.ws, D.cam, D.rec =
      vol, mute, mic, bri, bat, chg, full, ws, cam, rec
    dirty = true
  end)
end

local function artFinish(src)
  local dst = (noctalia.pluginDataDir() or "/tmp") .. "/island-art-bw.png"
  art.path = dst
  local cmd = ("command -v magick >/dev/null && magick '%s' -colorspace Gray"
    .. " -contrast-stretch 2%%x2%% -resize 176x176^ -gravity center -extent 176x176 png:'%s'"
    .. " || cp '%s' '%s'"):format(src, dst, src, dst)
  noctalia.runAsync(cmd, function(r2)
    art.ok = r2.exitCode == 0 and noctalia.fileExists(dst) or false
    if art.ok then dirty = true end
  end)
end
local function loadArt()
  local p = noctalia.mediaPlayer()
  local u = p and p.artUrl or ""
  if u == "" or u == art.url then return end
  art.url, art.ok = u, false
  local dir = noctalia.pluginDataDir() or "/tmp"
  if u:sub(1, 7) == "file://" then
    artFinish(u:sub(8))
  else
    noctalia.download(u, dir .. "/island-art-src", function(ok) if ok then artFinish(dir .. "/island-art-src") end end)
  end
end

local function pullWx()
  noctalia.runAsync("curl -s --max-time 5 'https://wttr.in/?format=%C;%t'", function(r)
    if r.exitCode == 0 and (r.stdout or "") ~= "" then
      wx.s, wx.t = (r.stdout:gsub("[%r%n]", "")), now()
      dirty = true
    end
  end)
end

local function checkEvents()
  local evs = noctalia.calendarEvents()
  if not evs then return end
  local n = now()
  for _, e in ipairs(evs) do
    local dt = e.startMs and (e.startMs - n) or -1
    if dt > 0 and dt <= 15 * 60000 and not e.allDay and e.id ~= evId then
      evId = e.id
      popEv("event", math.ceil(dt / 60000) .. "|" .. tostring(e.title or ""), 3000)
      break
    end
  end
end

local function swToggle() if swr then swacc = swacc + now() - swt0 swr = false else swt0 = now() swr = true end flush() end
local function swReset() swr, swacc, swt0 = false, 0, 0 flush() end
local function poToggle()
  if por then por = false
  else pleft = pleft > 0 and pleft or ptotal por = true end
  flush()
end
local function poSkip()
  por = false
  pphase = pphase == "focus" and "break" or "focus"
  ptotal = pphase == "focus" and FOC_MS or BRK_MS
  pleft = ptotal
  flush()
end
local function poTick(n, dtms)
  if not por then return end
  pleft = pleft - dtms
  if pleft <= 0 then
    por = false
    ppulse = n + 1400
    popEv("pomo", pphase, 3000)
    pphase = pphase == "focus" and "break" or "focus"
    ptotal = pphase == "focus" and FOC_MS or BRK_MS
    pleft = ptotal
    flush()
  end
end

local function expand() open, fullExp = true, now() + FULL_MS flush() end
local function collapse() open = false flush() end

function render()
  local ok, tree = pcall(buildFn)
  if ok and tree then layer.render(tree) return end
  if not FALLBACK then
    FALLBACK = true
    log("build failed -> clock-only fallback: " .. tostring(tree))
    ok, tree = pcall(buildFn)
    if ok and tree then layer.render(tree) end
  end
end
function tick()
  local want = false
  if not FALLBACK then
    local anim = math.abs(tw - W) > 0.5 or math.abs(th - H) > 0.5 or fade < 1
    local p = noctalia.mediaPlayer()
    local eqv = p ~= nil and p.status == "Playing" and now() >= pop.exp and not open
    want = anim or eqv or now() < ppulse
  end
  if want ~= ticking then ticking = want layer.setNeedsFrameTick(want) end
end
local function target()
  if FALLBACK then return "clock" end
  if now() < pop.exp then return "pop" end
  if open then return "full" end
  return "idle"
end

local function buildIdle(p, playing, n)
  local kids, w = {}, 26 -- 26 px is the pill's horizontal padding
  local function add(node, wd) kids[#kids + 1] = node w = w + wd + 10 end
  if D.ws then add(lab(D.ws, 12, SIL .. "77"), 20) end
  add(lab(lastMin, 15, TXT), 48)
  if por then add(lab(fmt(pleft), 13, ACC), 60)
  elseif swr then add(lab(fmt(swacc + n - swt0), 13, ACC), 60) end
  if playing then add(lab(p.title, 12, SIL, 130), 130) add(eq(n), 22) end
  if D.rec then add(gly("circle-dot", 13, ACC), 15) elseif D.cam then add(gly("video", 13, ACC), 15) end
  if D.mic then add(gly("microphone-off", 13, SIL .. "77"), 15) end
  if D.bat then
    if D.chg then add(gly("bolt", 12, ACC), 13) end
    add(lab(D.bat .. "%", 12, (D.bat <= 15 and not D.chg) and ACC or SIL .. "cc"), 46)
  end
  tw, th = w - 10, 44
  return kids
end

local function buildPop(p, n)
  tw, th = 300, 44
  local what, v = pop.what, pop.val
  local icon, acc = "info-circle", SIL
  if what == "vol" or what == "mute" then icon = what == "mute" and "volume-3" or "volume-2"
  elseif what == "bri" then icon = "sun"
  elseif what == "mic" or what == "micm" then icon = what == "micm" and "microphone-off" or "microphone"
  elseif what == "lowbat" then icon, acc = "battery-1", ACC
  elseif what == "charged" then icon, acc = "bolt", ACC
  elseif what == "cam" then icon, acc = "video", ACC
  elseif what == "rec" then icon, acc = "circle-dot", ACC
  elseif what == "event" then icon = "calendar-event"
  elseif what == "pomo" then icon, acc = "hourglass", ACC
  end
  local kids = { gly(icon, 16, acc) }
  if what == "vol" or what == "bri" then
    kids[2] = bar(v, 150, 6)
    kids[3] = lab(tostring(math.floor((v or 0) * 100 + 0.5)) .. "%", 13, TXT)
  elseif what == "event" then
    local m, title = tostring(v):match("^(%d+)|(.*)$")
    kids[2] = lab("in " .. (m or "?") .. "m", 12, SIL .. "99")
    kids[3] = lab(title or "", 12, TXT, 150)
  else
    local txt = what
    if what == "mute" then txt = "MUTE"
    elseif what == "micm" then txt = "MIC OFF"
    elseif what == "mic" then txt = "MIC ON"
    elseif what == "lowbat" then txt = "LOW " .. tostring(v) .. "%"
    elseif what == "charged" then txt = "FULL"
    elseif what == "cam" then txt = "CAMERA"
    elseif what == "rec" then txt = "REC"
    elseif what == "pomo" then txt = v == "focus" and "FOCUS DONE" or "BREAK DONE"
    end
    kids[2] = lab(txt, 13, TXT)
  end
  return kids
end

local function buildFull(p, playing, n)
  tw, th = 400, 258
  local st = noctalia.systemStats()
  local artNode
  if art.ok then
    artNode = ui.image({ path = art.path, width = 76, height = 76, radius = 10, fit = "cover",
                         border = EDGE, borderWidth = 1 })
  else
    artNode = ui.row({ width = 76, height = 76, radius = 10, fill = CARD, align = "center", justify = "center" },
                     { gly("disc", 26, SIL .. "44") })
  end
  local frac = (p and p.lengthMs and p.lengthMs > 0) and p.positionMs / p.lengthMs or 0
  local title = p and p.title or "Nothing playing"
  local artist = (p and p.artists and #p.artists > 0 and table.concat(p.artists, ", ")) or "—"
  local cpu = st and st.cpu and st.cpu.usagePercent or nil
  local wxs = wx.s ~= "" and wx.s or "—"
  return {
    ui.row({ gap = 8, align = "center", onClick = collapse },
           { gly("chevron-up", 14, SIL .. "88"), lab(lastMin, 13, TXT), lab(title, 12, SIL .. "cc", 184) }),
    ui.row({ gap = 12, align = "center" }, {
      artNode,
      ui.column({ gap = 6 }, {
        lab(title, 14, TXT, 268),
        lab(artist, 11, SIL .. "99", 268),
        bar(frac, 268, 4),
        ui.row({ gap = 8, align = "center" }, {
          lab(fmt(p and p.positionMs or 0) .. " / " .. fmt(p and p.lengthMs or 0), 10, SIL .. "99"),
          ghost("player-track-prev", function() run("noctalia msg media previous") end),
          ghost("player-track-next", function() run("noctalia msg media next") end),
          ui.box({ width = 42, height = 42, radius = 21, fill = ACC, softness = 14, -- the one glowing CTA
                   onClick = function() run("noctalia msg media toggle") end },
                 { ui.row({ width = 42, height = 42, align = "center", justify = "center" },
                          { gly(playing and "player-pause-filled" or "player-play-filled", 21, "#000000") }) }),
        }),
      }),
    }),
    ui.separator({ color = "#C9CED422", thickness = 1, spacing = 2, orientation = "horizontal" }),
    ui.row({ gap = 10, align = "center" }, {
      gly("clock", 13, SIL .. "88"),
      lab(fmt(swacc + (swr and n - swt0 or 0)), 13, TXT),
      ghost(swr and "player-pause" or "player-play", swToggle, 13),
      ghost("rotate", swReset, 12),
      ui.spacer({}),
      gly("hourglass", 13, por and ACC or SIL .. "88"),
      lab((pphase == "focus" and "FOC " or "BRK ") .. fmt(pleft), 13, por and ACC or SIL .. "99"),
      ghost(por and "player-pause" or "player-play", poToggle, 13),
      ghost("arrow-forward", poSkip, 12),
    }),
    ui.row({ gap = 12, align = "center" }, {
      gly("cpu", 13, SIL .. "88"),
      lab(cpu and string.format("CPU %2.0f%%", cpu) or "CPU —", 11, (cpu or 0) > 80 and ACC or SIL .. "cc"),
      lab(st and st.ram and string.format("RAM %2.0f%%", st.ram.usagePercent) or "RAM —", 11, SIL .. "cc"),
      lab(st and st.net and string.format("↓%.1f ↑%.1fM", st.net.rxBytesPerSec / 1e6, st.net.txBytesPerSec / 1e6) or "", 11, SIL .. "cc"),
      ui.spacer({}),
      gly("cloud", 12, SIL .. "88"),
      lab(wxs, 11, SIL .. "cc", 100),
    }),
    ui.row({ gap = 10, align = "center" }, {
      ghost("palette", function() run("noctalia msg theme-mode-toggle") end, 15),
      ghost("lock", function() run("noctalia msg session lock") end, 15),
      ghost("power", function() run("systemctl poweroff -i") end, 15),
      ui.spacer({}),
      lab(D.ws and "WS " .. D.ws or "", 10, SIL .. "55"),
      gly("chevron-down", 12, SIL .. "44"),
    }),
  }
end

buildFn = function()
  local n = now()
  local p = noctalia.mediaPlayer()
  local playing = p ~= nil and p.status == "Playing"
  local t = target()
  if t ~= shown then shown = t fade = 0 end
  local inner
  if t == "full" then
    inner = ui.column({ gap = 8, opacity = fade, align = "stretch", justify = "center",
                        paddingH = 14, paddingV = 10 }, buildFull(p, playing, n))
  elseif t == "pop" then
    inner = ui.row({ gap = 12, opacity = fade, align = "center", paddingH = 14,
                     onClick = function() pop.exp = 0 flush() end }, buildPop(p, n))
  else
    local kids
    if t == "clock" then tw, th = 96, 44 kids = { lab(lastMin, 14, TXT) }
    else kids = buildIdle(p, playing, n) end
    inner = ui.row({ gap = 10, opacity = fade, align = "center", paddingH = 13, onClick = expand }, kids)
  end
  return ui.column({ width = lw, height = lh, fill = PILL, radius = 22, border = edgeColor(n),
                     borderWidth = 1, align = "center", justify = "center" }, { inner })
end

function onFrameTick(ms)
  local n = now()
  local dt = clamp((tonumber(ms) or 16) / 1000, 0.001, 0.05)
  vw = (vw + (tw - W) * 300 * dt) * math.exp(-18 * dt)
  vh = (vh + (th - H) * 300 * dt) * math.exp(-18 * dt)
  W, H = W + vw * dt, H + vh * dt
  fade = clamp(fade + dt * 5, 0, 1)
  local w, h = math.floor(W + 0.5), math.floor(H + 0.5)
  if w ~= lw or h ~= lh then
    lw, lh = w, h
    local ok, e = pcall(noctalia.layer.configure, "island", { width = w, height = h })
    if not ok then log("configure: " .. tostring(e)) end
  end
  render()
  tick()
end

function update()
  local n = now()
  if n - pollAt >= 2000 then pollAt = n poll() end
  if n - wxAt >= WX_MS then wxAt = n pullWx() end
  loadArt()
  checkEvents()
  poTick(n, n - (lastUp or n))
  lastUp = n
  local m = noctalia.formatTime("%H:%M")
  if m ~= lastMin then lastMin = m dirty = true end
  if swr or por or open then dirty = true end -- live values need the 1 s re-render
  if open and n >= fullExp then open = false end
  if dirty then dirty = false render() end
  tick()
end

-- Init. exclusiveZone -1: the pill must not reserve space; keyboard stays with your windows.
pcall(noctalia.layer.configure, "island", { exclusiveZone = -1, keyboard = "none" })
noctalia.setUpdateInterval(1000)
poll()
pullWx()
wxAt = now()
render()
tick()
ISLAND_LUA_EOF

cat > "$STAGE/noctalia-plugin-island/plugin.toml" <<'ISLAND_TOML_EOF'
id = "jano/island"
name = "Island"
version = "0.2.0"
plugin_api = 51
author = "jano"

# One layer-shell entry: top-center pill on the focused output.
# Namespace niri sees: noctalia-plugin:jano/island:island
# exclusiveZone is also forced to -1 at runtime (see island.luau init), so the
# pill never reserves space or pushes your windows around.
[[layer]]
id = "island"
entry = "island.luau"
layer = "top"
anchors = ["top"]
margins = { top = 8 }
width = 200
height = 44
output = "focused"
exclusiveZone = -1
visible = true
ISLAND_TOML_EOF

for H in desktop laptop; do
  mkdir -p "$ROOT/hosts/$H/dotfiles/noctalia-plugin-island"
  cp "$STAGE/noctalia-plugin-island/island.luau" "$STAGE/noctalia-plugin-island/plugin.toml" \
     "$ROOT/hosts/$H/dotfiles/noctalia-plugin-island/"
done

cat > "$ROOT/hosts/desktop/dotfiles/niri-island-layer-rule.kdl" <<'ISLAND_KDL_EOF'
// niri layer-rule for the island pill (niri-unstable syntax, verified against
// the blur rules already present in hosts/*/dotfiles/niri/config.kdl).
//
// Both hosts' config.kdl already carry this rule with radius 24; radius 22
// matches the pill's capsule (height 44 / 2). Replace the old block with this
// one, or leave radius 24 — niri clamps it.
//
// The surface itself is resized every spring frame via noctalia.layer.configure,
// so the blur region always hugs the pill without any extra rules.

layer-rule {
    match namespace="^noctalia-plugin:jano/island:island$"
    geometry-corner-radius 22
    background-effect {
        blur true
        xray false
    }
}
ISLAND_KDL_EOF
cp "$ROOT/hosts/desktop/dotfiles/niri-island-layer-rule.kdl" "$ROOT/hosts/laptop/dotfiles/"

echo "wrote hosts/desktop/dotfiles/noctalia-plugin-island/{plugin.toml,island.luau}"
echo "wrote hosts/laptop/dotfiles/noctalia-plugin-island/{plugin.toml,island.luau}"
echo "wrote hosts/{desktop,laptop}/dotfiles/niri-island-layer-rule.kdl (merge into niri config.kdl if absent)"
echo
echo "-- verify (build errors and the clock-only fallback message land here) --"
echo "journalctl --user | command grep 'noctalia\\['"
echo
echo "-- apply without relogging (hot reload is not guaranteed for path sources) --"
echo "noctalia msg plugins disable jano/island; noctalia msg plugins enable jano/island"
