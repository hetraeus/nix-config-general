-- toggle_float_special.lua
--
-- Toggles all unpinned floating windows on the active workspace into/out of a
-- per-workspace special scratchpad (special:<workspace-name>).
--
-- Bind it like this in hyprland.lua:
--   hl.bind("SUPER + S", function() require("toggle_float_special")() end)
-- Or, if you put it somewhere on package.path, just call the returned function.
--
-- Logic (mirrors the original shell script):
--   1. If visible unpinned floaters exist on the current workspace → hide them.
--   2. Else if a special workspace is already open on any monitor → collapse it,
--      then move every window out of special:* back to the real workspace.
--   3. Else → show (restore) any floaters that were stashed in special:<name>.

local function toggle_float_special()
  local active_ws = hl.get_active_workspace()
  if not active_ws then return end

  local ws_name   = active_ws.name
  local spec_name = "special:" .. ws_name   -- e.g. "special:1"

  -- ── 1. Collect visible unpinned floaters on the current workspace ──────────
  local visible_floaters = {}
  for _, w in ipairs(hl.get_windows()) do
    if  w.floating
    and not w.pinned
    and w.workspace
    and w.workspace.name == ws_name
    then
      visible_floaters[#visible_floaters + 1] = w
    end
  end

  if #visible_floaters >= 1 then
    -- Hide all of them into their per-workspace special scratchpad
    for _, w in ipairs(visible_floaters) do
      hl.dispatch(hl.dsp.window.move({ workspace = spec_name, window = w, silent = true }))
    end
    return
  end

  -- ── 2. If a special workspace is open on any monitor, close it first ───────
  --   (mimics the "window switcher selected something" edge-case in the original)
  local special_open = false
  for _, mon in ipairs(hl.get_monitors()) do
    local sw = mon.active_special_workspace
    if sw and sw.name:match("^special:") then
      special_open = true
      break
    end
  end

  if special_open then
    -- Move whatever the compositor considers the active window in that
    -- special workspace back to the real workspace, then close the overlay.
    hl.dispatch(hl.dsp.window.move({ workspace = ws_name, silent = true }))
    hl.dispatch(hl.dsp.workspace.toggle_special(ws_name))

    -- If it is still showing (toggle didn't close it), toggle once more.
    for _, mon in ipairs(hl.get_monitors()) do
      local sw = mon.active_special_workspace
      if sw and sw.name:match("^special:") then
        hl.dispatch(hl.dsp.workspace.toggle_special(ws_name))
        break
      end
    end
    return
  end

  -- ── 3. Restore stashed floaters from the special workspace ─────────────────
  local hidden_floaters = {}
  for _, w in ipairs(hl.get_windows()) do
    if  w.floating
    and w.workspace
    and w.workspace.name == spec_name
    then
      hidden_floaters[#hidden_floaters + 1] = w
    end
  end

  for _, w in ipairs(hidden_floaters) do
    hl.dispatch(hl.dsp.window.move({ workspace = ws_name, window = w, silent = true }))
    hl.dispatch(hl.dsp.focus({ window = "floating" }))
  end
end

return toggle_float_special
