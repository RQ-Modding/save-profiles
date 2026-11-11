-- Save Profiles. The engine (rq.saves) does the file work: list, create, clone, import from the
-- vanilla game, rename, delete, switch (restarts the game). This file owns the title screen's
-- button and the manager, drawn with rq.uikit in the hub's theme (1.1.0, loader 2.29.0).

rq.log("Save Profiles: title-screen manager (file work lives in rq.saves)")

if not rq.saves.install() then
  error("save-profiles: rq.saves.install failed (see logs/rqmod.log)")
end

local ui = rq.uikit

local NAME_MAX = 40
local PW, PH = 880, 600 -- the manager
local QW, QH = 520, 192 -- the name prompt
local LIST_W = 380

local open = false
local profiles = {}
local vanilla = { exists = false }
local current_mods = {}
local selected = 1
local message, message_bad = nil, false
local prompt = nil  -- { kind, title, line, target, value }
local pending = nil -- { kind, id, name }: a question for the game's dialog, asked after drawing

local GOLD = { r = 255, g = 230, b = 160 }
local DIM = { r = 170, g = 170, b = 190 }
local BAD = { r = 255, g = 130, b = 120 }
local GOOD = { r = 150, g = 235, b = 160 }

local function label(x, y, str, size, col)
  size = size or 16
  col = col or { r = 245, g = 245, b = 255 }
  rq.hud.text(x + 1, y + 1, str, { size = size, r = 0, g = 0, b = 0 })
  rq.hud.text(x, y, str, { size = size, r = col.r, g = col.g, b = col.b })
end

-- Cut a string so it fits max_px at a size (or a style), adding "..." when it had to.
local function fit(str, max_px, size)
  str = tostring(str or "")
  if rq.hud.text_width(str, size) <= max_px then
    return str
  end
  while #str > 1 and rq.hud.text_width(str .. "...", size) > max_px do
    -- drop one UTF-8 character
    local cut = #str
    while cut > 1 and (str:byte(cut) & 0xC0) == 0x80 do
      cut = cut - 1
    end
    str = str:sub(1, cut - 1)
  end
  return str .. "..."
end

local function refresh()
  local list = rq.saves.list()
  if list then
    profiles = list
  end
  vanilla = rq.saves.vanilla() or { exists = false }
  current_mods = rq.saves.current_mods() or {}
  if selected > #profiles then
    selected = #profiles
  end
  if selected < 1 then
    selected = 1
  end
end

local function say(text, bad)
  message = text
  message_bad = bad and true or false
end

local function select_active()
  for i, p in ipairs(profiles) do
    if p.active then
      selected = i
      return
    end
  end
  selected = 1
end

local function active_name()
  for _, p in ipairs(profiles) do
    if p.active then
      return p.name
    end
  end
  return "?"
end

local function open_manager()
  open = true
  message = nil
  refresh()
  select_active()
end

local function close_manager()
  open = false
  prompt, pending = nil, nil
end

local function begin_prompt(kind, title, line, target, default)
  prompt = { kind = kind, title = title, line = line, target = target, value = default or "" }
end

local function summary_line(p, with_gold)
  local s = p.summary or {}
  if not s.has_save then
    return "No game save yet (a new game starts here)"
  end
  local bits = {}
  if s.world then
    bits[#bits + 1] = "World " .. s.world
  end
  if s.fame_rank then
    bits[#bits + 1] = "Rank " .. s.fame_rank
  end
  if s.quests then
    bits[#bits + 1] = s.quests .. " quests"
  end
  if with_gold and s.gold then
    bits[#bits + 1] = s.gold .. " G"
  end
  return table.concat(bits, "  |  ")
end

local function mod_label(m)
  if m.version and m.version ~= "" then
    return m.name .. " " .. m.version
  end
  return m.name
end

-- Mods the save was last written with vs. the mods loaded right now.
local function mod_diff(p)
  if not p.mods then
    return nil
  end
  local now = {}
  for _, m in ipairs(current_mods) do
    now[m.id] = m.version
  end
  local then_ = {}
  local missing, extra = {}, {}
  for _, m in ipairs(p.mods) do
    then_[m.id] = m.version
    if now[m.id] == nil then
      missing[#missing + 1] = m.name
    end
  end
  for _, m in ipairs(current_mods) do
    if then_[m.id] == nil then
      extra[#extra + 1] = m.name
    end
  end
  return missing, extra
end

local function prompt_ok()
  local kind, target, name = prompt.kind, prompt.target, prompt.value
  prompt = nil
  local ok, err
  if kind == "new" then
    ok, err = rq.saves.create(name)
  elseif kind == "clone" then
    ok, err = rq.saves.clone(target, name)
  elseif kind == "rename" then
    ok, err = rq.saves.rename(target, name)
  elseif kind == "import" then
    ok, err = rq.saves.import_vanilla(name)
  end
  if not ok then
    say(err or "That did not work.", true)
    return
  end
  refresh()
  if kind == "rename" then
    say("Renamed.")
  else
    -- select the new one
    for i, p in ipairs(profiles) do
      if p.id == ok then
        selected = i
      end
    end
    say("Created '" .. name .. "'.")
  end
end

-- Play and Delete ask with the game's own dialog. It returns when the player picks, and every
-- rq.on_frame callback (this file's too) runs while it shows, so it is asked after the drawing,
-- with the theme put back.
local function ask(a)
  if a.kind == "switch" then
    local yes = rq.ui.confirm("Play '" .. a.name .. "'?\nThe game restarts for a moment and opens this save.")
    if yes then
      say("Restarting the game...")
      local ok, err = rq.saves.switch(a.id)
      if not ok then
        say(err or "Could not switch.", true)
      end
    end
  elseif a.kind == "delete" then
    local yes = rq.ui.confirm("Delete '" .. a.name .. "'?\nEvery file of this save is removed. This cannot be undone.",
      { cursor = "no" })
    if yes then
      local ok, err = rq.saves.delete(a.id)
      if not ok then
        say(err or "Delete failed.", true)
        return
      end
      refresh()
      say("Deleted.")
    end
  end
end

local function draw_list(x, y, h, modal)
  local items = {}
  for i, p in ipairs(profiles) do
    items[i] = { text = p.name .. (p.active and "  (in use)" or ""), disabled = modal }
  end
  local index, changed = ui.list(items, selected, { x = x, y = y, w = LIST_W, h = h, row_h = 32, id = "saves" })
  if changed and not modal then
    selected = index
    message = nil
  end
end

-- dh: the column's height; the details take what the buttons and the note under them leave.
local function draw_detail(dx, dy, dw, dh, modal)
  local p = profiles[selected]
  if not p then
    return
  end
  local DH = dh - 108
  ui.draw("block", dx, dy, dw, DH)
  label(dx + 14, dy + 10, fit(p.name, dw - 28, 20), 20, GOLD)

  local y = dy + 40
  local s = p.summary or {}
  if s.has_save then
    label(dx + 14, y, summary_line(p, true), 14, nil)
    y = y + 20
    if s.saved_at then
      label(dx + 14, y, "Last game save: " .. s.saved_at .. (s.suspend and "  (has a suspend save)" or ""), 14, DIM)
      y = y + 20
    end
  else
    label(dx + 14, y, summary_line(p), 14, DIM)
    y = y + 20
  end
  if p.created then
    label(dx + 14, y, "Created: " .. p.created, 14, DIM)
    y = y + 20
  end
  local source = p.is_base and "Base save (cannot be deleted)" or p.source
  if source then
    label(dx + 14, y, fit(source, dw - 28, 14), 14, DIM)
    y = y + 20
  end

  y = y + 8
  label(dx + 14, y, "Mods in the last game save", 15, GOLD)
  y = y + 22
  if not p.mods then
    for _, line in ipairs(rq.hud.wrap("None recorded yet. This save has not been written by this install.", dw - 28, 14)) do
      label(dx + 14, y, line, 14, DIM)
      y = y + 18
    end
  elseif #p.mods == 0 then
    label(dx + 14, y, "No mods were loaded.", 14, DIM)
    y = y + 18
  else
    local shown = 0
    for _, m in ipairs(p.mods) do
      if shown >= 7 then
        label(dx + 14, y, "... and " .. (#p.mods - shown) .. " more", 14, DIM)
        y = y + 18
        break
      end
      label(dx + 14, y, fit("- " .. mod_label(m), dw - 28, 14), 14, nil)
      y = y + 18
      shown = shown + 1
    end
  end

  local missing, extra = mod_diff(p)
  if missing and (#missing > 0 or #extra > 0) then
    y = y + 6
    local parts = {}
    if #missing > 0 then
      parts[#parts + 1] = "Not loaded now: " .. table.concat(missing, ", ") .. "."
    end
    if #extra > 0 then
      parts[#parts + 1] = "Loaded now but not in this save: " .. table.concat(extra, ", ") .. "."
    end
    for _, line in ipairs(rq.hud.wrap(table.concat(parts, " "), dw - 28, 13)) do
      if y < dy + DH - 18 then
        label(dx + 14, y, line, 13, BAD)
        y = y + 16
      end
    end
  end

  -- The six buttons, two rows of three; greyed while the name prompt shows.
  local by = dy + DH + 12
  local bw = math.floor((dw - 16) / 3)
  local function button(text, col, row, id, enabled)
    return ui.button(text, { x = dx + (bw + 8) * col, y = by + 38 * row, w = bw, id = id,
      disabled = modal or not enabled })
  end
  if button(p.active and "Playing" or "Play", 0, 0, "saves-play", not p.active) then
    pending = { kind = "switch", id = p.id, name = p.name }
  end
  if button("Clone", 1, 0, "saves-clone", true) then
    begin_prompt("clone", "Clone", "A name for the copy of '" .. p.name .. "'.", p.id, p.name .. " copy")
  end
  if button("Rename", 2, 0, "saves-rename", true) then
    begin_prompt("rename", "Rename", "A new name for '" .. p.name .. "'.", p.id, p.is_base and "Original save" or p.name)
  end
  if button("Delete", 0, 1, "saves-delete", not p.is_base and not p.active) then
    pending = { kind = "delete", id = p.id, name = p.name }
  end
  if button("New empty", 1, 1, "saves-new", true) then
    begin_prompt("new", "New empty save", "A name for the new save. Its game starts from the beginning.", nil, "New save")
  end
  if button("From vanilla", 2, 1, "saves-import", vanilla.exists) then
    begin_prompt("import", "From vanilla", "A name for the copy of the original game's save.", nil, "Vanilla copy")
  end
  local note
  if p.is_base then
    note = "The base save cannot be deleted."
  elseif p.active then
    note = "Switch to another save to delete this one."
  elseif not vanilla.exists then
    note = "No vanilla save was found in Documents."
  end
  if note then
    label(dx + 2, by + 80, note, 13, DIM)
  end
end

-- The name prompt: a small page of its own on the top layer, over the manager. Enter is OK, Esc,
-- a right click and its close button are Cancel.
local function draw_prompt(sw, sh)
  local x, y = (sw - QW) // 2, (sh - QH) // 2
  local act
  ui.top(function()
    -- The page's own dim lets the manager show through; the prompt reads better on a darker box.
    rq.hud.rect(x, y, QW, QH, 0, 0, 0, 200)
    local still = ui.page({ id = "saves-name", title = prompt.title, x = x, y = y, w = QW, h = QH }, function(cx, cy, cw)
      label(cx, cy + 6, fit(prompt.line, cw, 15), 15, nil)
      local value, _, ended = ui.input(prompt.value, { id = "saves-name", x = cx, y = cy + 30, w = cw,
        max = NAME_MAX, focus = true, placeholder = "A name" })
      prompt.value = value
      local blank = not value:match("%S")
      if ended == "enter" and not blank then act = "ok" end
      if ended == "esc" then act = "cancel" end
      label(cx, cy + 66, "Letters, digits and kana. Enter is OK, Esc cancels.", 13, DIM)
      if ui.button("OK", { x = cx + cw - 248, y = cy + 92, w = 120, id = "saves-ok", disabled = blank }) then
        act = act or "ok"
      end
      if ui.button("Cancel", { x = cx + cw - 120, y = cy + 92, w = 120, id = "saves-cancel" }) then
        act = act or "cancel"
      end
    end)
    if not still then act = act or "cancel" end
  end)
  return act
end

local function draw_manager(sw, sh)
  local px, py = (sw - PW) // 2, (sh - PH) // 2
  local modal = prompt ~= nil
  local still = ui.page({ id = "saves", title = "Save Manager", x = px, y = py, w = PW, h = PH }, function(cx, cy, cw, ch)
    -- The list starts at the title tab's bottom edge (the kit's page, 2.29.0), so the tab touches it.
    draw_list(cx, cy, ch - 34, modal)
    draw_detail(cx + LIST_W + 20, cy, cw - LIST_W - 20, ch - 34, modal)
    if message then
      label(cx, cy + ch - 22, fit(message, cw, 15), 15, message_bad and BAD or GOOD)
    else
      label(cx, cy + ch - 22, "Pick a save, then Play. Clone first to try mods on a copy.", 14, DIM)
    end
  end)
  if prompt then
    local act = draw_prompt(sw, sh)
    -- A right click or the manager's close button while the prompt shows cancels the prompt only.
    if not still then act = act or "cancel" end
    if act == "ok" then
      prompt_ok()
    elseif act == "cancel" then
      prompt = nil
    end
  elseif not still then
    close_manager()
  end
end

local function draw_title()
  if ui.button("Save Manager", { x = 16, y = 16, w = 250, id = "saves-open" }) then
    open_manager()
  end
  label(20, 52, "Save: " .. fit(active_name(), 226, 13), 13, GOLD)
end

-- The kit's theme is shared by every mod: the hub's is used while this draws, then put back.
local function themed(fn, ...)
  local was = ui.theme
  ui.use(ui.themes.hub)
  local ok, err = pcall(fn, ...)
  ui.use(was)
  if not ok then
    error(err, 0)
  end
end

rq.on_frame(function()
  if not rq.saves.title() then
    if open then
      close_manager()
    end
    return
  end
  if #profiles == 0 then
    refresh()
  end
  local sw, sh = rq.hud.screen()
  themed(open and draw_manager or draw_title, sw, sh)
  if pending then
    local a = pending
    pending = nil
    ask(a)
  end
end)
