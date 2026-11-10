--!nonstrict
local expanded = false

local function playerctl(cmd)
  pcall(function()
    noctalia.runAsync({ "playerctl", cmd })
  end)
end

local build

local function refresh()
  local ok, tree = pcall(build)
  if not ok then
    noctalia.log("island build error: " .. tostring(tree))
    tree = ui.row({ fill = "surface/0.55", radius = 24, paddingH = 18, paddingV = 10 }, {
      ui.label({ text = noctalia.formatTime("%H:%M"), fontSize = 14, color = "on_surface" }),
    })
  end
  layer.render(tree)
end

local function toggle()
  expanded = not expanded
  pcall(noctalia.layer.configure, "island", { width = 340, height = expanded and 140 or 44 })
  refresh()
end

local function control(glyph, cmd)
  return ui.row({ paddingH = 8, onClick = function() playerctl(cmd) end }, {
    ui.label({ text = glyph, fontSize = 18, color = "on_surface" }),
  })
end

local function artistText(p)
  local a = p.artists
  if type(a) == "table" then
    return table.concat(a, ", ")
  end
  return a or ""
end

build = function()
  local clock = noctalia.formatTime("%H:%M")
  local p = noctalia.mediaPlayer()
  local frame = {
    fill = "surface/0.55",
    radius = 24,
    border = "on_surface/0.2",
    borderWidth = 1,
    align = "center",
    justify = "center",
    flexGrow = 1,
  }

  if not expanded or p == nil then
    frame.paddingH = 18
    frame.paddingV = 10
    frame.gap = 10
    frame.onClick = toggle
    local kids = {
      ui.label({ text = clock, fontSize = 14, fontWeight = "bold", color = "on_surface" }),
    }
    if p ~= nil and p.title and p.status == "Playing" then
      kids[#kids + 1] = ui.label({ text = p.title, fontSize = 13, color = "on_surface/0.8", maxWidth = 220, maxLines = 1 })
    end
    return ui.row(frame, kids)
  end

  local total = 260
  local len = p.lengthMs or 0
  local pos = p.positionMs or 0
  local filled = 0
  if len > 0 then
    filled = math.max(0, math.min(total, math.floor(total * pos / len)))
  end

  frame.paddingH = 20
  frame.paddingV = 14
  frame.gap = 8
  frame.minWidth = 300
  return ui.column(frame, {
    ui.row({ gap = 10, align = "center", onClick = toggle }, {
      ui.label({ text = clock, fontSize = 14, fontWeight = "bold", color = "on_surface" }),
      ui.label({ text = p.title or "", fontSize = 14, color = "on_surface", maxWidth = 200, maxLines = 1 }),
    }),
    ui.label({ text = artistText(p), fontSize = 12, color = "on_surface/0.7", maxWidth = 280, maxLines = 1 }),
    ui.row({}, {
      ui.box({ fill = "primary", width = filled, height = 4, radius = 2 }),
      ui.box({ fill = "on_surface/0.2", width = total - filled, height = 4, radius = 2 }),
    }),
    ui.row({ gap = 16, align = "center" }, {
      control("⏮", "previous"),
      control("⏯", "play-pause"),
      control("⏭", "next"),
    }),
  })
end

function update()
  refresh()
end

refresh()
