-- Save Profiles. The engine (rq.saves) does the file work: list, create,
-- clone, import from the vanilla game, rename, delete, switch (restarts the
-- game). This file owns the title-screen button and the manager window.

rq.log("Save Profiles: title-screen manager (file work lives in rq.saves)")

if not rq.saves.install() then
  error("save-profiles: rq.saves.install failed (see logs/rqmod.log)")
end

local VK_RETURN = 13
local VK_ESCAPE = 27

local ROW_H = 76
local ROWS = 6
local NAME_MAX = 40

local open = false
local mode = "list" -- list | prompt | confirm
local profiles = {}
local vanilla = { exists = false }
local current_mods = {}
local selected = 1
local scroll = 0
local message = nil
local message_bad = false
local prompt = nil -- { kind, title, target, default }
local confirm = nil -- { kind, title, lines, target }
local prev_enter, prev_esc = false, false
local agents_now, agents_prev = {}, {}

local function agent_rect(id, x, y, w, h, text)
  agents_now[id] = true
  rq.agent.control(id, { label = text, x = x, y = y, w = w, h = h })
end

local function agent_sweep()
  for id in pairs(agents_prev) do
    if not agents_now[id] then
      rq.agent.control(id)
    end
  end
  agents_prev, agents_now = agents_now, {}
end

local function frame(x, y, w, h, r, g, b, a)
  a = a or 255
  rq.hud.rect(x, y, w, 2, r, g, b, a)
  rq.hud.rect(x, y + h - 2, w, 2, r, g, b, a)
  rq.hud.rect(x, y, 2, h, r, g, b, a)
  rq.hud.rect(x + w - 2, y, 2, h, r, g, b, a)
end

local function label(x, y, str, size, col)
  size = size or 16
  col = col or { r = 245, g = 245, b = 255 }
  rq.hud.text(x + 1, y + 1, str, { size = size, r = 0, g = 0, b = 0 })
  rq.hud.text(x, y, str, { size = size, r = col.r, g = col.g, b = col.b })
end

local GOLD = { r = 255, g = 230, b = 160 }
local DIM = { r = 170, g = 170, b = 190 }
local BAD = { r = 255, g = 130, b = 120 }
local GOOD = { r = 150, g = 235, b = 160 }

-- Cut a string so it fits max_px, adding "..." when it had to.
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

-- id: agent control id. enabled=false greys it and ignores clicks.
local function button(id, x, y, w, h, text, enabled, accent)
  if enabled == nil then
    enabled = true
  end
  local hot = enabled and rq.hud.hit(x, y, w, h)
  if not enabled then
    rq.hud.rect(x, y, w, h, 28, 26, 32, 235)
  elseif hot then
    rq.hud.rect(x, y, w, h, 96, 74, 40, 245)
  elseif accent then
    rq.hud.rect(x, y, w, h, 60, 44, 24, 240)
  else
    rq.hud.rect(x, y, w, h, 36, 28, 18, 235)
  end
  frame(x, y, w, h, enabled and 220 or 90, enabled and 200 or 90, enabled and 140 or 100, 255)
  local col = enabled and nil or DIM
  local tw = rq.hud.text_width(text, 16)
  label(x + math.floor((w - tw) / 2), y + math.floor((h - 16) / 2) - 1, text, 16, col)
  if enabled then
    agent_rect(id, x, y, w, h, text)
  end
  return enabled and rq.hud.clicked(x, y, w, h)
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

local function open_manager()
  open = true
  mode = "list"
  message = nil
  scroll = 0
  refresh()
  select_active()
end

local function close_manager()
  open = false
  mode = "list"
  prompt, confirm = nil, nil
  rq.hud.text_end()
end

local function begin_prompt(kind, title, target, default)
  prompt = { kind = kind, title = title, target = target, default = default }
  mode = "prompt"
  rq.hud.text_begin(default or "", NAME_MAX)
end

local function begin_confirm(kind, title, lines, target)
  confirm = { kind = kind, title = title, lines = lines, target = target }
  mode = "confirm"
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

local function do_prompt_ok(name)
  local kind, target = prompt.kind, prompt.target
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
  rq.hud.text_end()
  prompt = nil
  mode = "list"
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

local function do_confirm_ok()
  local kind, target = confirm.kind, confirm.target
  confirm = nil
  mode = "list"
  if kind == "delete" then
    local ok, err = rq.saves.delete(target)
    if not ok then
      say(err or "Delete failed.", true)
      return
    end
    refresh()
    say("Deleted.")
  elseif kind == "switch" then
    say("Restarting the game...")
    local ok, err = rq.saves.switch(target)
    if not ok then
      say(err or "Could not switch.", true)
    end
  end
end

local function draw_list(px, py, pw, ph, enabled)
  local lx, ly, lw = px + 16, py + 64, 392
  local count = #profiles
  if scroll > math.max(0, count - ROWS) then
    scroll = math.max(0, count - ROWS)
  end
  for row = 1, ROWS do
    local idx = scroll + row
    local p = profiles[idx]
    if not p then
      break
    end
    local y = ly + (row - 1) * ROW_H
    local hot = enabled and rq.hud.hit(lx, y, lw, ROW_H - 6)
    if idx == selected then
      rq.hud.rect(lx, y, lw, ROW_H - 6, 70, 54, 30, 245)
    elseif hot then
      rq.hud.rect(lx, y, lw, ROW_H - 6, 44, 38, 30, 240)
    else
      rq.hud.rect(lx, y, lw, ROW_H - 6, 28, 24, 36, 235)
    end
    frame(lx, y, lw, ROW_H - 6, idx == selected and 230 or 90, idx == selected and 205 or 84, idx == selected and 130 or 100, 255)
    local tag = ""
    if p.active then
      tag = "ACTIVE"
    end
    local tagw = tag ~= "" and (rq.hud.text_width(tag, 13) + 16) or 0
    label(lx + 12, y + 8, fit(p.name, lw - 28 - tagw, 19), 19, GOLD)
    if tag ~= "" then
      label(lx + lw - tagw - 4 + 8, y + 11, tag, 13, GOOD)
    end
    local sub = p.is_base and "Base save (cannot be deleted)" or (p.source or "")
    label(lx + 12, y + 33, fit(sub, lw - 28, 13), 13, DIM)
    label(lx + 12, y + 51, fit(summary_line(p), lw - 28, 13), 13, nil)
    agent_rect("saves-row-" .. idx, lx, y, lw, ROW_H - 6, p.name)
    if enabled and rq.hud.clicked(lx, y, lw, ROW_H - 6) then
      selected = idx
      message = nil
    end
  end
  if count > ROWS then
    local by = ly + ROWS * ROW_H - 2
    if button("saves-scroll-up", lx, by, 190, 26, "Up", enabled and scroll > 0) then
      scroll = scroll - 1
    end
    if button("saves-scroll-down", lx + 202, by, 190, 26, "Down", enabled and scroll < count - ROWS) then
      scroll = scroll + 1
    end
  end
end

local function draw_detail(px, py, pw, ph, enabled)
  local dx, dy, dw = px + 424, py + 64, pw - 440
  local p = profiles[selected]
  if not p then
    return
  end
  rq.hud.rect(dx, dy, dw, 366, 22, 20, 32, 235)
  frame(dx, dy, dw, 366, 90, 84, 100, 255)
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
  if p.source then
    label(dx + 14, y, fit(p.source, dw - 28, 14), 14, DIM)
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
      if y < dy + 366 - 18 then
        label(dx + 14, y, line, 13, BAD)
        y = y + 16
      end
    end
  end

  -- Actions
  local by = dy + 378
  local bw = math.floor((dw - 16) / 3)
  local is_active = p.active
  if button("saves-play", dx, by, bw, 34, is_active and "Playing" or "Play", enabled and not is_active, true) then
    begin_confirm("switch", "Play '" .. p.name .. "'?", {
      "The game restarts for a moment and",
      "opens this save.",
    }, p.id)
  end
  if button("saves-clone", dx + bw + 8, by, bw, 34, "Clone", enabled) then
    begin_prompt("clone", "Clone '" .. p.name .. "'", p.id, p.name .. " copy")
  end
  if button("saves-rename", dx + (bw + 8) * 2, by, bw, 34, "Rename", enabled) then
    begin_prompt("rename", "Rename '" .. p.name .. "'", p.id, p.is_base and "Original save" or p.name)
  end
  local can_delete = enabled and not p.is_base and not p.active
  if button("saves-delete", dx, by + 42, bw, 34, "Delete", can_delete) then
    begin_confirm("delete", "Delete '" .. p.name .. "'?", {
      "Every file of this save is removed.",
      "This cannot be undone.",
    }, p.id)
  end
  if button("saves-new", dx + bw + 8, by + 42, bw, 34, "New empty", enabled) then
    begin_prompt("new", "New empty save", nil, "New save")
  end
  if button("saves-import", dx + (bw + 8) * 2, by + 42, bw, 34, "From vanilla", enabled and vanilla.exists) then
    begin_prompt("import", "Import the vanilla save", nil, "Vanilla copy")
  end
  if p.is_base then
    label(dx + 2, by + 82, "The base save cannot be deleted.", 13, DIM)
  elseif p.active then
    label(dx + 2, by + 82, "Switch to another save to delete this one.", 13, DIM)
  elseif not vanilla.exists then
    label(dx + 2, by + 82, "No vanilla save was found in Documents.", 13, DIM)
  end
end

local function dialog_box(sw, sh, title, w, h)
  rq.hud.rect(0, 0, sw, sh, 0, 0, 0, 120)
  local x, y = math.floor((sw - w) / 2), math.floor((sh - h) / 2)
  rq.hud.rect(x, y, w, h, 20, 18, 30, 252)
  frame(x, y, w, h, 230, 205, 130, 255)
  rq.hud.rect(x + 2, y + 2, w - 4, 36, 48, 36, 22, 255)
  label(x + 14, y + 9, fit(title, w - 28, 18), 18, GOLD)
  return x, y
end

local function draw_prompt(sw, sh, enter, esc)
  local w, h = 520, 190
  local x, y = dialog_box(sw, sh, prompt.title, w, h)
  local value = rq.hud.text_value()
  rq.hud.rect(x + 16, y + 56, w - 32, 38, 8, 8, 14, 255)
  frame(x + 16, y + 56, w - 32, 38, 150, 140, 100, 255)
  local blink = (os.clock() * 2) % 2 < 1
  label(x + 26, y + 66, value .. (blink and "|" or ""), 18, nil)
  label(x + 16, y + 100, "Letters, digits and kana. Enter confirms, Esc cancels.", 12, DIM)
  local ok_click = button("saves-ok", x + w - 244, y + h - 50, 110, 34, "OK", value:match("%S") ~= nil, true)
  local cancel_click = button("saves-cancel", x + w - 126, y + h - 50, 110, 34, "Cancel", true)
  if (ok_click or enter) and value:match("%S") then
    do_prompt_ok(value)
  elseif cancel_click or esc then
    rq.hud.text_end()
    prompt = nil
    mode = "list"
  end
end

local function draw_confirm(sw, sh, enter, esc)
  local w, h = 480, 170
  local x, y = dialog_box(sw, sh, confirm.title, w, h)
  for i, line in ipairs(confirm.lines) do
    label(x + 16, y + 50 + (i - 1) * 22, line, 16, nil)
  end
  local yes = confirm.kind == "delete" and "Delete" or "Play"
  local ok_click = button("saves-confirm", x + w - 244, y + h - 50, 110, 34, yes, true, true)
  local cancel_click = button("saves-cancel", x + w - 126, y + h - 50, 110, 34, "Cancel", true)
  if ok_click or enter then
    do_confirm_ok()
  elseif cancel_click or esc then
    confirm = nil
    mode = "list"
  end
end

rq.on_frame(function()
  local enter = rq.input.key(VK_RETURN)
  local esc = rq.input.key(VK_ESCAPE)
  local enter_edge = enter and not prev_enter
  local esc_edge = esc and not prev_esc
  prev_enter, prev_esc = enter, esc

  if not rq.saves.title() then
    if open then
      close_manager()
    end
    agent_sweep()
    return
  end

  local sw, sh = rq.hud.screen()
  local active_name = "?"
  for _, p in ipairs(profiles) do
    if p.active then
      active_name = p.name
    end
  end
  if #profiles == 0 then
    refresh()
  end

  if not open then
    local bw, bh = 250, 40
    local bx, by = 16, 16
    local caption = "Save Manager"
    if rq.hud.hit(bx, by, bw, bh) then
      rq.hud.block_game_input()
    end
    if button("saves-open", bx, by, bw, bh, caption, true, true) then
      open_manager()
    end
    local who = "Save: " .. fit(active_name, bw - 40, 13)
    label(bx + 4, by + bh + 4, who, 13, GOLD)
    agent_sweep()
    return
  end

  rq.hud.block_game_input()
  rq.hud.block_keys()
  rq.hud.rect(0, 0, sw, sh, 0, 0, 0, 170)

  local pw, ph = 880, 640
  local px, py = math.floor((sw - pw) / 2), math.floor((sh - ph) / 2)
  rq.hud.rect(px, py, pw, ph, 18, 16, 28, 248)
  frame(px, py, pw, ph, 210, 190, 120, 255)
  rq.hud.rect(px + 2, py + 2, pw - 4, 44, 48, 36, 22, 255)
  label(px + 16, py + 12, "Save Manager", 22, GOLD)

  local list_live = mode == "list"
  if button("saves-close", px + pw - 126, py + 8, 110, 30, "Close", list_live) then
    close_manager()
    agent_sweep()
    return
  end
  draw_list(px, py, pw, ph, list_live)
  draw_detail(px, py, pw, ph, list_live)

  if message then
    label(px + 16, py + ph - 34, fit(message, pw - 32, 15), 15, message_bad and BAD or GOOD)
  else
    label(px + 16, py + ph - 34, "Pick a save, then Play. Clone first to try mods on a copy.", 14, DIM)
  end

  if mode == "list" and esc_edge then
    close_manager()
  elseif mode == "prompt" and prompt then
    draw_prompt(sw, sh, enter_edge, esc_edge)
  elseif mode == "confirm" and confirm then
    draw_confirm(sw, sh, enter_edge, esc_edge)
  end
  agent_sweep()
end)
