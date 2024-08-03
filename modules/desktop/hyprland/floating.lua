--[[
  Smart Floating Window Placement for Hyprland 0.55
  - Places floating windows in a non-overlapping grid
  - Keeps windows strictly inside the monitor workarea when possible
  - Falls back to minimal-overflow cascade only when too many are open
  - Respects reserved screen space (waybar, panels, etc.)
--]]

local config = {
  gap = 10,              -- Gap between windows and from screen edges
  cascade_step = 40,     -- Offset per window in cascade fallback mode
  max_attempts = 100,    -- How many positions to try before allowing overflow
}

-- Extract window geometry, handling different API shapes
local function get_geometry(w)
  local x, y, width, height

  -- Hyprland IPC exposes "at" [x, y] and "size" [w, h]
  if w.at then
    x = w.at[1] or w.at.x or 0
    y = w.at[2] or w.at.y or 0
  else
    x = w.x or (w.position and w.position.x) or 0
    y = w.y or (w.position and w.position.y) or 0
  end

  if w.size then
    width = w.size[1] or w.size.width or w.size.w or 800
    height = w.size[2] or w.size.height or w.size.h or 600
  else
    width = w.width or w.w or 800
    height = w.height or w.h or 600
  end

  return { x = x, y = y, width = width, height = height }
end

-- Get usable monitor area (minus reserved space like waybar/docks)
local function get_workarea(m)
  local reserved = m.reserved or { top = 0, bottom = 0, left = 0, right = 0 }
  return {
    x = (m.x or 0) + (reserved.left or 0) + config.gap,
    y = (m.y or 0) + (reserved.top or 0) + config.gap,
    width = (m.width or 1920) - (reserved.left or 0) - (reserved.right or 0) - 2 * config.gap,
    height = (m.height or 1080) - (reserved.top or 0) - (reserved.bottom or 0) - 2 * config.gap,
  }
end

-- Rectangle overlap check
local function overlaps(a, b)
  return a.x < b.x + b.width and a.x + a.width > b.x and
         a.y < b.y + b.height and a.y + a.height > b.y
end

-- Get other floating windows on the same monitor
local function get_sibling_floats(target, monitor)
  local all = hl.get_windows()
  local siblings = {}
  local target_id = target.address or target.id

  for _, w in ipairs(all) do
    if w ~= target and w.floating then
      local w_mon = w.monitor
      if type(w_mon) == "table" then w_mon = w_mon.id end
      local target_mon = monitor.id or monitor.name
      if w_mon == target_mon then
        table.insert(siblings, w)
      end
    end
  end
  return siblings
end

-- Find the best position for a window
local function find_position(w, monitor)
  local geom = get_geometry(w)
  local work = get_workarea(monitor)
  local siblings = get_sibling_floats(w, monitor)

  local existing = {}
  for _, s in ipairs(siblings) do
    table.insert(existing, get_geometry(s))
  end

  local cell_w = geom.width + config.gap
  local cell_h = geom.height + config.gap
  local cols = math.max(1, math.floor(work.width / cell_w))
  local rows = math.max(1, math.floor(work.height / cell_h))

  -- Strategy 1: Strict grid placement inside workarea
  for r = 0, rows - 1 do
    for c = 0, cols - 1 do
      local pos = {
        x = work.x + c * cell_w,
        y = work.y + r * cell_h,
        width = geom.width,
        height = geom.height,
      }

      -- Must fit inside bounds
      if pos.x + pos.width <= work.x + work.width + config.gap and
         pos.y + pos.height <= work.y + work.height + config.gap then

        local hit = false
        for _, e in ipairs(existing) do
          if overlaps(pos, e) then
            hit = true
            break
          end
        end

        if not hit then
          return pos.x, pos.y
        end
      end
    end
  end

  -- Strategy 2: Cascade with wrapping (still tries to stay in bounds)
  for i = 1, config.max_attempts do
    local pos = {
      x = work.x + (i - 1) * config.cascade_step,
      y = work.y + (i - 1) * config.cascade_step,
      width = geom.width,
      height = geom.height,
    }

    -- Wrap around to stay near screen
    while pos.x + pos.width > work.x + work.width and pos.x > work.x do
      pos.x = pos.x - math.floor(work.width / 2)
    end
    while pos.y + pos.height > work.y + work.height and pos.y > work.y do
      pos.y = pos.y - math.floor(work.height / 2)
    end

    local hit = false
    for _, e in ipairs(existing) do
      if overlaps(pos, e) then
        hit = true
        break
      end
    end

    if not hit then
      return pos.x, pos.y
    end
  end

  -- Strategy 3: Overflow mode - find position with minimal overlap
  local best_x, best_y = work.x, work.y
  local min_overlap = math.huge

  for r = 0, rows + 2 do
    for c = 0, cols + 2 do
      local pos = {
        x = work.x + c * cell_w,
        y = work.y + r * cell_h,
        width = geom.width,
        height = geom.height,
      }

      local overlap_area = 0
      for _, e in ipairs(existing) do
        if overlaps(pos, e) then
          local ox = math.min(pos.x + pos.width, e.x + e.width) - math.max(pos.x, e.x)
          local oy = math.min(pos.y + pos.height, e.y + e.height) - math.max(pos.y, e.y)
          overlap_area = overlap_area + (ox * oy)
        end
      end

      if overlap_area < min_overlap then
        min_overlap = overlap_area
        best_x, best_y = pos.x, pos.y
      end
    end
  end

  return best_x, best_y
end

-- Returns true if any window rule applied to `w` sets an explicit move position.
-- Such windows should be left alone — their placement is intentional.
local function has_move_rule(w)
  local rules = w.rules or w.windowrules or {}
  for _, r in ipairs(rules) do
    -- Rules may be plain strings ("move 100 200") or tables ({ rule = "move", ... })
    if type(r) == "string" then
      if r:match("^move%s") then return true end
    elseif type(r) == "table" then
      local rule_name = r.rule or r.name or ""
      if rule_name:match("^move") or r.move then return true end
    end
  end
  return false
end

-- Main placement dispatcher
local function place_window(w)
  if not w or not w.floating then return end
  if has_move_rule(w) then return end

  local monitor = w.monitor
  if type(monitor) == "number" or type(monitor) == "string" then
    monitor = hl.get_monitor(monitor)
  end
  if not monitor then
    monitor = hl.get_active_monitor()
  end
  if not monitor then return end

  local x, y = find_position(w, monitor)

  hl.dispatch(hl.dsp.window.move({
    x = x,
    y = y,
    relative = false,
    window = w,
  }))
end

-- Track each window's last-known floating state so we can detect transitions.
-- Keyed by window address/id; value is the boolean floating state.
local floating_state = {}

local function window_id(w)
  return w.address or w.id
end

-- When a new window opens, place it after a short delay so geometry is finalized
hl.on("window.open", function(w)
  floating_state[window_id(w)] = w.floating
  hl.timer(function()
    place_window(w)
  end, { timeout = 50, type = "oneshot" })
end)

-- Clean up state table when a window closes to avoid memory leaks
hl.on("window.close", function(w)
  floating_state[window_id(w)] = nil
end)

-- When window rules change, only auto-place on tiled → floating transitions.
-- Firing on every update_rules would fight the user every time they drag a window,
-- because moving a floating window re-evaluates its rules.
hl.on("window.update_rules", function(w)
  local id   = window_id(w)
  local prev = floating_state[id]         -- nil = window was just opened (handled above)
  local curr = w.floating

  floating_state[id] = curr

  -- Only place when the window *becomes* floating from a tiled state
  if curr and prev == false then
    hl.timer(function()
      place_window(w)
    end, { timeout = 50, type = "oneshot" })
  end
end)

-- Manual placement keybind for the active window
hl.bind("SUPER + SHIFT + F", function()
  local w = hl.get_active_window()
  if w then
    place_window(w)
  end
end)

-- Optional: Re-tile all floating windows on the current monitor
hl.bind("SUPER + SHIFT + R", function()
  local monitor = hl.get_active_monitor()
  if not monitor then return end
  local mon_id = monitor.id or monitor.name

  for _, w in ipairs(hl.get_windows()) do
    if w.floating then
      local w_mon = w.monitor
      if type(w_mon) == "table" then w_mon = w_mon.id end
      if w_mon == mon_id then
        place_window(w)
      end
    end
  end
end)
