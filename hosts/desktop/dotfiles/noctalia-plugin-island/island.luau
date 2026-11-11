--!nonstrict
-- jano/island v0.3.0 — iPhone Dynamic Island, rebuilt for the niri + Noctalia desktop.
--
-- Four modules live inside one pill, laid out like iOS Live Activities:
--   1 COSMOS  clock, date, weather + a little starfield with a shooting comet
--   2 MEDIA   album art (B&W via magick), progress, equalizer, glowing orange CTA
--   3 TIMER   stopwatch + 25/5 pomodoro (edge pulse on completion)
--   4 SYSTEM  battery, volume/brightness sliders, CPU/RAM/NET, theme/lock/power
--
-- Swipe: two-finger horizontal scroll (or mouse wheel) over the pill switches
-- modules with a two-phase slide+fade while the surface springs to each
-- module's own size — the Dynamic Island "goo" morph. Click a dot or the
-- header chevrons to jump without scrolling. Click the pill to expand.
-- Transient events (volume, mic, camera, recorder, battery, calendar,
-- pomodoro) pop over everything for ~1.8 s, then the previous module returns.
--
-- Palette (hard-coded, "cosmos"): deep-space fill #0A0C18 over niri blur,
-- nebula violet #8B7CF6 + pink #E06AC4, signature orange #FF5A1F, silver text.
--
-- UNVERIFIED (adjust if something renders oddly):
--   * onScroll on layer entries — supported since v5.0.0-beta.3; argument
--     units are undocumented, so this reads the dominant delta and needs an
--     accumulated |delta| >= 60 to fire. Fallbacks: header chevrons + dots.
--   * ui.slider inside layer entries — pointer controls work in bar widgets,
--     layers should behave the same; if not, the journal shows a skip warning
--     and the rows degrade to glyphs + labels.
--   * Tabler glyph names; font family auto-probed at startup via fc-match.
--   * file:// artUrl percent-encoding is not decoded (host-side %20 stays).
-- Build errors go to noctalia.log and fall back to a clock-only pill.

local ACC, SIL, TXT = "#FF5A1F", "#C9CED4", "#F2F4F7"
local NEB1, NEB2 = "#8B7CF6", "#E06AC4"          -- nebula violet / pink
local SPACE, CARD = "#0A0C18D9", "#161A2E99"     -- pill fill / inner cards
local EDGE = "#8B7CF655"                          -- violet edge glow
local FONT = "JetBrains Mono"
local FOC_MS, BRK_MS = 25 * 60000, 5 * 60000
local POP_MS, FULL_MS, WX_MS = 1800, 10000, 15 * 60000
local EXP_W = 440                                 -- expanded panel width

local D = { vol = nil, mute = false, mic = false, bri = nil, bat = nil, chg = false,
            batFull = false, lowArm = false, ws = nil, cam = false, rec = false }
local open, fullExp = false, 0
local pop = { what = "", val = "", exp = 0 }
local swr, swacc, swt0 = false, 0, 0
local por, pleft, ptotal, pphase, ppulse = false, FOC_MS, FOC_MS, "focus", 0
local W, H, vw, vh, tw, th, lw, lh = 200, 44, 0, 0, 200, 44, 200, 44
local fade, shown, dirty, ticking = 1, "", true, false
local lastMin, lastDate, lastUp, pollAt, wxAt = noctalia.formatTime("%H:%M"), nil, nil, 0, 0
local art = { url = "", path = "", ok = false }
local wx = { s = "", t = 0 }
local evId = ""
local FALLBACK = false
local cur = 1                                     -- active module index
local slide = nil                                 -- { dir, t0, from } while swiping
local swAcc, swT = 0, 0                           -- scroll accumulator
local wasPlaying = false

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
  return ui.row({ key = "gh-" .. g, width = 30, height = 30, radius = 15, align = "center",
                  justify = "center", onClick = fn }, { gly(g, size or 15, SIL) })
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
local function dot(color, h) -- module identity tick on the idle pill
  return ui.box({ width = 3, height = h or 16, radius = 1, fill = color })
end
local function glow(color, wd) -- soft nebula aura
  return ui.box({ width = wd or 120, height = 18, radius = 9, fill = color, softness = 40 })
end

local buildFn, render, tick -- forward declarations: flush() re-renders immediately
local function popEv(what, val, ms)
  pop = { what = what, val = val, exp = now() + (ms or POP_MS) }
  slide = nil
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
      if chg and not D.chg and bat then popEv("chg", bat) end
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

-- Swipe machinery: an onScroll delta accumulator + a two-phase slide anim.
local function swipeTo(dir)
  if slide or FALLBACK then return end
  local n = now()
  slide = { dir = dir, t0 = n, from = cur }
  cur = ((cur - 1 + dir) % 4) + 1
  if open then fullExp = n + FULL_MS end
  flush()
end
function onScroll(...) -- tolerant parse: host docs do not pin the signature down
  local nums = {}
  for i = 1, select("#", ...) do
    local v = tonumber(select(i, ...))
    if v then nums[#nums + 1] = v end
  end
  local d = 0
  if #nums >= 2 then
    if math.abs(nums[1]) >= math.abs(nums[2]) then d = nums[1] else d = nums[2] end
  elseif #nums == 1 then
    d = nums[1]
  end
  if d == 0 then return end
  local n = now()
  if n - (swT or 0) > 400 then swAcc = 0 end
  swT, swAcc = n, swAcc + d
  if math.abs(swAcc) >= 60 then
    swipeTo(swAcc > 0 and 1 or -1)
    swAcc = 0
  end
end
local function jumpTo(i)
  if i == cur or slide then return end
  local n = now()
  slide = { dir = i > cur and 1 or -1, t0 = n, from = cur }
  cur = i
  if open then fullExp = n + FULL_MS end
  flush()
end

-- ============================== MODULE: COSMOS ==============================
local STARS = { 12, 41, 66, 95, 118, 149, 176, 198, 227, 252, 279, 305, 330, 357, 381, 402 }
local function starBand(n, odd, wd)
  local kids, x = {}, 0
  for i, xx in ipairs(STARS) do
    if (i % 2 == 1) == odd then
      kids[#kids + 1] = ui.box({ width = xx - x - 2, height = 2 })
      local a = 0.18 + 0.6 * math.abs(math.sin(n / 900 + i * 1.7))
      kids[#kids + 1] = ui.box({ width = 2, height = 2, radius = 1,
                                 fill = SIL .. string.format("%02x", math.floor(a * 255 + 0.5)) })
      x = xx
    end
  end
  kids[#kids + 1] = ui.box({ width = math.max(0, wd - x), height = 2 })
  return ui.row({ height = 4, align = "center" }, kids)
end
local function cometBand(n, wd)
  local ph = (n / 2800) % 1
  local x = 10 + ph * (wd - 30)
  local a = math.sin(math.pi * ph)
  return ui.row({ height = 2, align = "center" }, {
    ui.box({ width = math.floor(x), height = 2 }),
    ui.box({ width = 10, height = 2, radius = 1,
             fill = ACC .. string.format("%02x", math.floor(a * 210 + 0.5)) }),
    ui.box({ width = math.max(0, wd - math.floor(x) - 10), height = 2 }),
  })
end
local function cosCompact(p, playing, n)
  local kids = { dot(NEB1) }
  kids[2] = lab(lastDate or "", 11, SIL .. "77")
  kids[3] = lab(lastMin, 15, TXT)
  tw, th = 26 + 13 + 10 + 38 + 10 + 48 - 10, 44
  return kids
end
local function cosFull(p, playing, n)
  local cond, temp = wx.s:match("^(.-);(.+)$")
  local line = lastDate or ""
  if cond and temp then line = line .. "   ·   " .. cond .. " " .. temp end
  return ui.column({ gap = 8, align = "stretch", justify = "center" }, {
    starBand(n, false, EXP_W - 28),
    cometBand(n, EXP_W - 28),
    starBand(n, true, EXP_W - 28),
    ui.row({ justify = "center" }, {
      ui.label({ text = lastMin, fontSize = 34, color = TXT, fontWeight = "heavy",
                 fontFamily = FONT, shadow = true, maxLines = 1 }),
    }),
    ui.row({ justify = "center" }, { lab(line, 11, SIL .. "99") }),
  })
end

-- ============================== MODULE: MEDIA ===============================
local function medCompact(p, playing, n)
  local kids = { dot(ACC) }
  kids[2] = gly("disc", 15, SIL .. "88")
  kids[3] = lab(p and p.title or "Nothing playing", 12, SIL, 110)
  kids[4] = eq(n)
  tw, th = 26 + 13 + 10 + 25 + 10 + 120 + 10 + 22 - 10, 44
  return kids
end
local function medFull(p, playing, n)
  local artNode
  if art.ok then
    artNode = ui.image({ path = art.path, width = 72, height = 72, radius = 10, fit = "cover",
                         border = EDGE, borderWidth = 1 })
  else
    artNode = ui.row({ width = 72, height = 72, radius = 10, fill = CARD, align = "center",
                       justify = "center" }, { gly("disc", 24, SIL .. "44") })
  end
  local frac = (p and p.lengthMs and p.lengthMs > 0) and p.positionMs / p.lengthMs or 0
  local title = p and p.title or "Nothing playing"
  local artist = (p and p.artists and #p.artists > 0 and table.concat(p.artists, ", ")) or "—"
  return ui.column({ gap = 8, align = "stretch" }, {
    ui.row({ gap = 12, align = "center" }, {
      artNode,
      ui.column({ gap = 5 }, {
        lab(title, 14, TXT, 322),
        lab(artist, 11, SIL .. "99", 322),
        eq(n),
      }),
    }),
    bar(frac, EXP_W - 28, 4),
    ui.row({ justify = "space_between" }, {
      lab(fmt(p and p.positionMs or 0), 10, SIL .. "99"),
      lab(fmt(p and p.lengthMs or 0), 10, SIL .. "99"),
    }),
    ui.row({ gap = 14, justify = "center", align = "center" }, {
      ghost("player-track-prev", function() run("noctalia msg media previous") end),
      ui.box({ key = "cta", width = 42, height = 42, radius = 21, fill = ACC, softness = 14, -- the glowing CTA
               onClick = function() run("noctalia msg media toggle") end },
             { ui.row({ width = 42, height = 42, align = "center", justify = "center" },
                      { gly(playing and "player-pause-filled" or "player-play-filled", 21, "#000000") }) }),
      ghost("player-track-next", function() run("noctalia msg media next") end),
    }),
  })
end

-- ============================== MODULE: TIMER ===============================
local function timCompact(p, playing, n)
  local kids = { dot(NEB2) }
  kids[2] = gly("hourglass", 14, por and ACC or SIL .. "88")
  if por then
    kids[3] = lab((pphase == "focus" and "FOC " or "BRK ") .. fmt(pleft), 13, ACC)
    tw, th = 26 + 13 + 10 + 24 + 10 + 100 - 10, 44
  elseif swr then
    kids[3] = lab(fmt(swacc + n - swt0), 13, ACC)
    tw, th = 26 + 13 + 10 + 24 + 10 + 60 - 10, 44
  else
    kids[3] = lab(fmt(0), 13, SIL .. "55")
    tw, th = 26 + 13 + 10 + 24 + 10 + 34 - 10, 44
  end
  return kids
end
local function timFull(p, playing, n)
  return ui.column({ gap = 10, align = "stretch", justify = "center" }, {
    ui.row({ gap = 10, align = "center" }, {
      gly("clock", 15, SIL .. "88"),
      lab(fmt(swacc + (swr and n - swt0 or 0)), 20, TXT),
      ghost(swr and "player-pause" or "player-play", swToggle, 14),
      ghost("rotate", swReset, 13),
      ui.spacer({}),
      lab("STOPWATCH", 9, SIL .. "44"),
    }),
    ui.separator({ color = "#C9CED41A", thickness = 1, spacing = 2, orientation = "horizontal" }),
    ui.row({ gap = 10, align = "center" }, {
      gly("hourglass", 15, por and ACC or NEB2),
      lab((pphase == "focus" and "FOC " or "BRK ") .. fmt(pleft), 20, por and ACC or SIL .. "99"),
      ghost(por and "player-pause" or "player-play", poToggle, 14),
      ghost("arrow-forward", poSkip, 13),
      ui.spacer({}),
      lab("POMODORO 25/5", 9, SIL .. "44"),
    }),
    bar(1 - clamp(pleft / ptotal, 0, 1), EXP_W - 28, 5, NEB2, "#E06AC422"),
  })
end

-- ============================== MODULE: SYSTEM ==============================
local function sysSlider(g, val, onChange)
  return ui.row({ key = "sl-" .. g, gap = 10, align = "center" }, {
    gly(g, 14, SIL .. "88"),
    ui.slider({ min = 0, max = 100, step = 5, value = clamp(math.floor((val or 0) + 0.5), 0, 100),
                controlSize = "sm", flexGrow = 1, onChange = onChange }),
    lab(math.floor((val or 0) + 0.5) .. "%", 11, SIL .. "cc"),
  })
end
local function sysCompact(p, playing, n)
  local kids = { dot(SIL) }
  local i = 2
  if D.ws then kids[i] = lab(D.ws, 12, SIL .. "77") i = i + 1 end
  if D.rec then kids[i] = gly("circle-dot", 13, ACC) i = i + 1 elseif D.cam then kids[i] = gly("video", 13, ACC) i = i + 1 end
  if D.mic then kids[i] = gly("microphone-off", 13, SIL .. "77") i = i + 1 end
  if D.bat then
    if D.chg then kids[i] = gly("bolt", 12, ACC) i = i + 1 end
    kids[i] = lab(D.bat .. "%", 12, (D.bat <= 15 and not D.chg) and ACC or SIL .. "cc") i = i + 1
  end
  if i == 2 then kids[i] = lab("—", 12, SIL .. "55") i = i + 1 end
  local w = 26
  for k = 2, i - 1 do w = w + 10 + (k == 2 and 20 or (k == i - 1 and 46 or 20)) end
  tw, th = w - 10, 44
  return kids
end
local function sysFull(p, playing, n)
  local st = noctalia.systemStats()
  local cpu = st and st.cpu and st.cpu.usagePercent or nil
  local wxs = wx.s ~= "" and (wx.s:gsub(";", "  ")) or "—"
  local batFill = (D.bat and D.bat <= 15 and not D.chg) and ACC or NEB1
  return ui.column({ gap = 8, align = "stretch" }, {
    ui.row({ gap = 10, align = "center" }, {
      gly(D.chg and "bolt" or "battery-1", 14, D.chg and ACC or SIL .. "88"),
      bar((D.bat or 0) / 100, 150, 6, batFill),
      lab(D.bat and (D.bat .. "%") or "—", 11, SIL .. "cc"),
      ui.spacer({}),
      lab(D.chg and "CHARGING" or "", 9, ACC),
    }),
    sysSlider("volume-2", (D.vol or 0) * 100, function(v)
      local nv = clamp(tonumber(v) or 0, 0, 100)
      D.vol = nv / 100
      fullExp = now() + FULL_MS
      run("wpctl set-volume @DEFAULT_AUDIO_SINK@ " .. math.floor(nv + 0.5) .. "%")
    end),
    sysSlider("sun", D.bri or 0, function(v)
      local nv = clamp(tonumber(v) or 0, 0, 100)
      D.bri = nv
      fullExp = now() + FULL_MS
      run("brightnessctl set -q " .. math.floor(nv + 0.5) .. "%")
    end),
    ui.row({ gap = 10, align = "center" }, {
      gly("cpu", 13, SIL .. "88"),
      lab(cpu and string.format("CPU %2.0f%%", cpu) or "CPU —", 11, (cpu or 0) > 80 and ACC or SIL .. "cc"),
      lab(st and st.ram and string.format("RAM %2.0f%%", st.ram.usagePercent) or "RAM —", 11, SIL .. "cc"),
      lab(st and st.net and string.format("↓%.1f ↑%.1fM", st.net.rxBytesPerSec / 1e6, st.net.txBytesPerSec / 1e6) or "", 11, SIL .. "cc"),
      ui.spacer({}),
      gly("cloud", 12, SIL .. "88"),
      lab(wxs, 11, SIL .. "cc", 110),
    }),
    ui.row({ gap = 10, align = "center" }, {
      ghost("palette", function() run("noctalia msg theme-mode-toggle") end, 15),
      ghost("lock", function() run("noctalia msg session lock") end, 15),
      ghost("power", function() run("systemctl poweroff -i") end, 15),
      ui.spacer({}),
      lab(D.ws and "WS " .. D.ws or "", 10, SIL .. "55"),
    }),
  })
end

-- ============================ MODULE REGISTRY ===============================
local MODULES = {
  { id = "cosmos", name = "COSMOS", col = NEB1, h = 186, compact = cosCompact, expanded = cosFull },
  { id = "media",  name = "MEDIA",  col = ACC,  h = 176, compact = medCompact, expanded = medFull },
  { id = "timer",  name = "TIMER",  col = NEB2, h = 150, compact = timCompact, expanded = timFull },
  { id = "system", name = "SYSTEM", col = SIL,  h = 200, compact = sysCompact, expanded = sysFull },
}

local function buildPop(p, n)
  tw, th = 320, 44
  local what, v = pop.what, pop.val
  local icon, acc = "info-circle", SIL
  if what == "vol" or what == "mute" then icon = what == "mute" and "volume-3" or "volume-2"
  elseif what == "bri" then icon = "sun"
  elseif what == "mic" or what == "micm" then icon = what == "micm" and "microphone-off" or "microphone"
  elseif what == "lowbat" then icon, acc = "battery-1", ACC
  elseif what == "charged" or what == "chg" then icon, acc = "bolt", ACC
  elseif what == "cam" then icon, acc = "video", ACC
  elseif what == "rec" then icon, acc = "circle-dot", ACC
  elseif what == "event" then icon = "calendar-event"
  elseif what == "pomo" then icon, acc = "hourglass", ACC
  end
  local kids = { gly(icon, 16, acc) }
  if what == "vol" or what == "bri" then
    kids[2] = bar(v, 160, 6)
    kids[3] = lab(tostring(math.floor((v or 0) * 100 + 0.5)) .. "%", 13, TXT)
  elseif what == "event" then
    local m, title = tostring(v):match("^(%d+)|(.*)$")
    kids[2] = lab("in " .. (m or "?") .. "m", 12, SIL .. "99")
    kids[3] = lab(title or "", 12, TXT, 160)
  else
    local txt = what
    if what == "mute" then txt = "MUTE"
    elseif what == "micm" then txt = "MIC OFF"
    elseif what == "mic" then txt = "MIC ON"
    elseif what == "lowbat" then txt = "LOW " .. tostring(v) .. "%"
    elseif what == "charged" then txt = "FULL"
    elseif what == "chg" then txt = "CHARGING " .. tostring(v) .. "%"
    elseif what == "cam" then txt = "CAMERA"
    elseif what == "rec" then txt = "REC"
    elseif what == "pomo" then txt = v == "focus" and "FOCUS DONE" or "BREAK DONE"
    end
    kids[2] = lab(txt, 13, TXT)
  end
  return kids
end

-- Slide phase: nil | { out, k } — two phases of 120 ms.
local function slideState(n)
  if not slide then return nil end
  local ph = n - slide.t0
  if ph >= 240 then return nil end
  if ph < 120 then return { out = true, k = ph / 120 } end
  return { out = false, k = (ph - 120) / 120 }
end

buildFn = function()
  local n = now()
  local p = noctalia.mediaPlayer()
  local playing = p ~= nil and p.status == "Playing"
  local t = "idle"
  if FALLBACK then t = "clock"
  elseif now() < pop.exp then t = "pop"
  elseif open then t = "full" end
  if t ~= shown then shown = t fade = 0 end

  local inner
  if t == "pop" then
    inner = ui.row({ gap = 12, opacity = fade, align = "center", paddingH = 14,
                     onClick = function() pop.exp = 0 flush() end }, buildPop(p, n))
  elseif t == "full" then
    local m = MODULES[cur]
    local s = slideState(n)
    local cm = s and s.out and MODULES[slide.from] or m
    local content = cm.expanded(p, playing, n)
    local pad, op = 0, fade
    if s then
      if s.out then pad, op = -slide.dir * 26 * s.k, fade * (1 - s.k)
      else pad, op = slide.dir * 26 * (1 - s.k), fade * s.k end
    end
    local dots = {}
    for i = 1, #MODULES do
      dots[i] = ui.box({ key = "dot" .. i, width = i == cur and 18 or 6, height = 6, radius = 3,
                         fill = i == cur and m.col or SIL .. "33",
                         onClick = function() jumpTo(i) end })
    end
    inner = ui.column({ gap = 8, align = "stretch", opacity = fade, paddingH = 14, paddingV = 10 }, {
      ui.row({ height = 18, align = "center" }, { glow("#8B7CF62E"), ui.spacer({}), glow("#E06AC426") }),
      ui.row({ gap = 6, align = "center" }, {
        ghost("chevron-left", function() swipeTo(-1) end, 13),
        dot(m.col, 10),
        lab(m.name, 11, SIL .. "88"),
        ui.spacer({}),
        lab(lastMin, 11, SIL .. "77"),
        ghost("chevron-up", collapse, 13),
      }),
      ui.row({ height = m.h, align = "center", paddingH = pad, opacity = op },
             { ui.column({ width = EXP_W - 28, align = "stretch", justify = "center" }, { content }) }),
      ui.row({ gap = 5, justify = "center", align = "center" }, dots),
    })
    tw, th = EXP_W, 106 + m.h
  else
    local m = MODULES[cur]
    local s = slideState(n)
    local mi = s and s.out and slide.from or cur
    local kids, w = MODULES[mi].compact(p, playing, n)
    local pad, op = 13, fade
    if s then
      if s.out then pad, op = 13 - slide.dir * 20 * s.k, fade * (1 - s.k)
      else pad, op = 13 + slide.dir * 20 * (1 - s.k), fade * s.k end
    end
    if t == "clock" then tw, th = 96, 44 kids = { lab(lastMin, 14, TXT) } pad = 13 end
    inner = ui.row({ gap = 10, opacity = op, align = "center", paddingH = pad, onClick = expand }, kids)
  end
  local alert = t == "pop" and (pop.what == "lowbat" or pop.what == "charged" or pop.what == "chg"
    or pop.what == "cam" or pop.what == "rec" or pop.what == "pomo")
  return ui.column({ width = lw, height = lh, fill = SPACE, radius = 22,
                     border = alert and ACC .. "AA" or edgeColor(n),
                     borderWidth = 1, align = "center", justify = "center" }, { inner })
end

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
    local anim = math.abs(tw - W) > 0.5 or math.abs(th - H) > 0.5 or fade < 1 or slide ~= nil
    local p = noctalia.mediaPlayer()
    local eqv = p ~= nil and p.status == "Playing" and cur == 2 and now() >= pop.exp and not open
    local decor = open and (cur == 1 or (cur == 2 and p ~= nil and p.status == "Playing"))
    want = anim or eqv or decor or now() < ppulse
  end
  if want ~= ticking then ticking = want layer.setNeedsFrameTick(want) end
end

function onFrameTick(ms)
  local n = now()
  local dt = clamp((tonumber(ms) or 16) / 1000, 0.001, 0.05)
  vw = (vw + (tw - W) * 300 * dt) * math.exp(-18 * dt)
  vh = (vh + (th - H) * 300 * dt) * math.exp(-18 * dt)
  W, H = W + vw * dt, H + vh * dt
  fade = clamp(fade + dt * 5, 0, 1)
  if slide and n - slide.t0 >= 240 then slide = nil end
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
  local p = noctalia.mediaPlayer()
  local playing = p ~= nil and p.status == "Playing"
  if swr or por then -- the timer module always wins while it runs (like an iOS activity)
    if cur ~= 3 then cur = 3 slide = nil dirty = true end
  elseif playing and not wasPlaying then
    if cur == 1 or cur == 4 then cur = 2 slide = nil dirty = true end
  elseif not playing and wasPlaying and cur == 2 then
    cur = 1 slide = nil dirty = true
  end
  wasPlaying = playing
  local m = noctalia.formatTime("%H:%M")
  if m ~= lastMin then lastMin = m dirty = true end
  local d = noctalia.formatTime("%a %d")
  if d ~= lastDate then lastDate = d dirty = true end
  if swr or por or open then dirty = true end -- live values need the 1 s re-render
  if open and n >= fullExp then open = false end
  if dirty then dirty = false render() end
  tick()
end

-- Init. exclusiveZone -1: the pill must not reserve space; keyboard stays with your windows.
pcall(noctalia.layer.configure, "island", { exclusiveZone = -1, keyboard = "none" })
noctalia.setUpdateInterval(1000)
-- Probe the exact registered family name so JetBrains Mono renders bold mono.
noctalia.runAsync("fc-match -f '%{family}' 'JetBrains Mono:style=Bold'", function(r)
  local f = (r.stdout or ""):match("^([^,\n]+)")
  if f and f ~= "" and f ~= FONT then FONT = f dirty = true end
end)
poll()
pullWx()
wxAt = now()
lastDate = noctalia.formatTime("%a %d")
render()
tick()
