-- ~/.config/hypr/hyprland.lua
-- Converted from hyprlang to Lua for Hyprland 0.55+
-- https://wiki.hypr.land/Configuring/Start/

--------------------------------------------------------------------------------
-- MONITOR
--------------------------------------------------------------------------------

hl.monitor({
  output   = "",
  mode     = "preferred",
  position = "auto",
  scale    = 1,
})


--------------------------------------------------------------------------------
-- GLOBAL CONFIG
--------------------------------------------------------------------------------

hl.config({
  animations = {
    enabled = true,
  },

  binds = {
    allow_workspace_cycles           = true,
    focus_preferred_method           = 0,
    hide_special_on_workspace_change = true,
    workspace_back_and_forth         = true,
  },

  cursor = {
    persistent_warps = true,
    zoom_factor      = 1,
  },

  debug = {
    disable_logs = false,
  },

  decoration = {
    rounding = 0,
    blur     = { enabled = false },
    -- shadow   = {
    --   color        = "rgba(26323899)",
    --   enabled      = false,
    --   range        = 4,
    --   render_power = 3,
    -- },
  },

  dwindle = {
    force_split                  = 2,
    permanent_direction_override = true,
    preserve_split               = true,
  },

  ecosystem = {
    enforce_permissions = true,
    no_donation_nag     = true,
    no_update_news      = true,
  },

  general = {
    snap              = { enabled = true },
    allow_tearing     = false,
    border_size       = 5,
    col               = {
      --   active_border   = "rgb(89ddff)",
      inactive_border = "rgb(272727)",
    },
    gaps_in           = 0,
    gaps_out          = 2,
    layout            = "scrolling",
    no_focus_fallback = true,
    resize_on_border  = false,
  },

  gestures = {
    workspace_swipe_forever = true,
  },

  -- group = {
  --   groupbar = {
  --     col        = {
  --       active   = "rgb(89ddff)",
  --       inactive = "rgb(707880)",
  --     },
  --     font_size  = 12,
  --     text_color = "rgb(cdd3de)",
  --   },
  --   col = {
  --     border_active        = "rgb(89ddff)",
  --     border_inactive      = "rgb(707880)",
  --     border_locked_active = "rgb(80cbc4)",
  --   },
  -- },

  input = {
    focus_on_close      = 1,
    -- kb_layout           = "it",
    special_fallthrough = true,
  },

  master = {
    new_status = "slave",
  },

  misc = {
    animate_manual_resizes       = false,
    animate_mouse_windowdragging = false,
    anr_missed_pings             = 3,
    -- background_color             = "rgb(263238)",
    disable_hyprland_logo        = true,
    disable_splash_rendering     = true,
    force_default_wallpaper      = 1,
  },

  scrolling = {
    column_width = 0.66,
  },
})

hl.window_rule({
  -- Fix some dragging issues with XWayland
  name     = "fix-xwayland-drags",
  match    = {
    class      = "^$",
    title      = "^$",
    xwayland   = true,
    float      = true,
    fullscreen = false,
    pin        = false,
  },

  no_focus = true,
})

--------------------------------------------------------------------------------
-- ANIMATIONS & CURVES
--------------------------------------------------------------------------------

hl.curve("mylinear", { type = "bezier", points = { { 0.63, 0.72 }, { 0.77, 1 } } })

hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "default", style = "slidevert" })
hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "default", style = "popin" })
hl.animation({ leaf = "layers", enabled = true, speed = 2, bezier = "default", style = "popin" })
hl.animation({ leaf = "fadePopups", enabled = false, speed = 0, bezier = "default" })
hl.animation({ leaf = "fadeOut", enabled = false, speed = 0, bezier = "default" })

--------------------------------------------------------------------------------
-- GESTURES
--------------------------------------------------------------------------------

hl.gesture({ fingers = 4, direction = "vertical", action = "workspace" })
hl.gesture({ fingers = 3, direction = "horizontal", action = "scroll_move" })
-- hl.gesture({ fingers = 3, direction = "vertical", action = "scroll_move" })

--------------------------------------------------------------------------------
-- LAYER RULES
--------------------------------------------------------------------------------

hl.layer_rule({ match = { namespace = "^(rofi)$" }, no_anim = true })
hl.layer_rule({ match = { namespace = "^(swaync-control-center)$" }, no_anim = true })

--------------------------------------------------------------------------------
-- WINDOW RULES
--------------------------------------------------------------------------------

hl.window_rule({ match = { class = "^(org.keepassxc.KeePassXC)$" }, no_screen_share = true })
hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })
hl.window_rule({ match = { class = "^(thunar)$" }, workspace = "1" })
hl.window_rule({ match = { class = "^(pcmanfm-qt)$" }, workspace = "1" })
hl.window_rule({ match = { class = "^(pcmanfm-qt)$", title = "^(Current)$" }, workspace = "+0" })
hl.window_rule({ match = { class = "^(thunderbird)$" }, fullscreen = true })
hl.window_rule({ match = { class = "^(thunderbird)$", title = "^(Calendar Reminders)$" }, float = true })
hl.window_rule({ match = { class = "^(qimgv)$", title = "^(Edit shortcut)$" }, float = true })
hl.window_rule({ match = { class = "^(qimgv)$", title = "^(Add shortcut)$" }, float = true })
hl.window_rule({ match = { class = "^(wev)$" }, float = true })
hl.window_rule({ match = { class = "^(puzzles-" }, float = true })
hl.window_rule({ match = { class = "^(zenity)$" }, float = true })
hl.window_rule({ match = { class = "^(gcolor3)$" }, float = true })
hl.window_rule({ match = { class = "^(songrec)$" }, float = true })
hl.window_rule({ match = { class = "^(Spyglass)$" }, float = true })
hl.window_rule({ match = { class = "^(kitty_floating)$" }, float = true })
hl.window_rule({ match = { class = "^(file-pdf-export)$" }, float = true })
hl.window_rule({ match = { class = "(exo-desktop-item-edit)" }, float = true })
hl.window_rule({ match = { class = "^(.blueman-manager-wrapped)$" }, float = true })
hl.window_rule({ match = { class = "^(SourceGit)$", title = "^(File History)$" }, float = true })
hl.window_rule({ match = { title = "^(Copy Files)$" }, float = true })
hl.window_rule({ match = { title = "^(File Properties)$" }, float = true })
hl.window_rule({ match = { title = "^(Authentication Required)$" }, float = true })
hl.window_rule({ match = { class = "^(fmenu-movie)$" }, float = true, size = "48% 48%" })
hl.window_rule({
  name = "satty_test",
  match = { class = "^(com.gabm.satty)$" },
  float = true,
  pin = true,
  no_anim = true,
  no_initial_focus = true,
  fullscreen_state = "3",                                               
})

hl.window_rule({
  match       = { class = "^(com.github.hluk.copyq)$" },
  float       = true,
  border_size = 2,
  move        = "(cursor_x-(window_w*0.2)) (cursor_y-(window_h*0.07))",
  no_anim     = true,
})
hl.window_rule({ match = { class = "^(mov_foot)$" }, workspace = "3" })
hl.window_rule({ match = { class = "^(terminal_media_player)$" }, workspace = "3", float = true })
hl.window_rule({
  match = { class = "^(fmenu_panel)$" },
  float = true,
  size = "26.8% 99%",
  move = "73% .5%",
})
hl.window_rule({ match = { class = "^(fmenu_todo)$" }, float = true, size = "50% 49%" })
hl.window_rule({ match = { class = "^(mpv)$" }, workspace = "4", fullscreen = true, border_size = 0 })
hl.window_rule({ match = { class = "^(music_dashboard)$" }, workspace = "3", fullscreen = true })
hl.window_rule({ match = { class = "^(log_dashboard)$" }, workspace = "11", fullscreen = true })
hl.window_rule({ match = { class = "^(network_dashboard)$" }, workspace = "11", fullscreen = true })
hl.window_rule({ match = { class = "^(firefox)$" }, workspace = "2" })
hl.window_rule({ match = { class = "^(firefox)$", title = "^(Library)$" }, float = true })
hl.window_rule({
  match = { class = "^(firefox)$", title = "^(Picture-in-Picture)$" },
  float = true,
  pin = true,
  tag =
  "+dontclose"
})
hl.window_rule({
  match = { class = "kando" },
  border_size = 0,
  no_anim = true,
  float = true,
  pin = true,
  size = "100% 100%",
  opaque = true,
  no_blur = true,
})
hl.window_rule({
  match = { class = "^(org.pulseaudio.pavucontrol)$" },
  float = true,
  size = "24.8% 49.5%",
  move = "75% 50%",
})
hl.window_rule({
  match = { class = "^(com.saivert.pwvucontrol)$" },
  float = true,
  size = "24.8% 49.5%",
  move = "75% 50%",
})
hl.window_rule({
  match = { initial_title = "^(Reading from stdin...)$" },
  workspace = "+0",
  float = true,
  pin = true,
  move = "(cursor_x-(window_w*0.2)) (cursor_y-(window_h*0.1))",
})
hl.window_rule({
  match = { title = "^(Blobdrop)$" },
  workspace = "+0",
  float = true,
  pin = true,
  move = "(cursor_x-(window_w*0.2)) (cursor_y-(window_h*0.1))",
})
hl.window_rule({
  match = { class = "^(blobdrop)$" },
  move  = "(cursor_x-(window_w*0.2)) (cursor_y-(window_h*0.1))",
})
hl.window_rule({
  match = { class = "^(ripdrag)$" },
  float = true,
  pin = true,
  move = "(cursor_x-(window_w*0.2)) (cursor_y-(window_h*0.1))",
})

--------------------------------------------------------------------------------
-- WORKSPACE RULES
--------------------------------------------------------------------------------

for i = 1, 10 do
  hl.workspace_rule({ workspace = tostring(i), persistent = true })
end
hl.workspace_rule({ workspace = "11", persistent = true, default = true })

hl.bind("SUPER + Tab", function()
  hl.dispatch(hl.dsp.window.cycle_next({ next = true }))
  hl.dispatch(hl.dsp.window.bring_to_top())
end)

hl.bind("SUPER + SHIFT + Tab", function()
  hl.dispatch(hl.dsp.window.cycle_next({ next = false }))
  hl.dispatch(hl.dsp.window.bring_to_top())
end)

--------------------------------------------------------------------------------
-- KEYBINDINGS — swap windows
--------------------------------------------------------------------------------

hl.bind("SUPER + CONTROL + left", hl.dsp.window.swap({ direction = "l" }))
hl.bind("SUPER + CONTROL + right", hl.dsp.window.swap({ direction = "r" }))
hl.bind("SUPER + CONTROL + up", hl.dsp.window.swap({ direction = "u" }))
hl.bind("SUPER + CONTROL + down", hl.dsp.window.swap({ direction = "d" }))
--------------------------------------------------------------------------------
-- KEYBINDINGS — key swallowing (no-op binds to suppress default actions)
--------------------------------------------------------------------------------

hl.bind("CONTROL + SHIFT + W", hl.dsp.exec_cmd("true"))
hl.bind("CONTROL + Q", hl.dsp.exec_cmd("true"))
hl.bind("KP_Insert", hl.dsp.exec_cmd("true"))

--------------------------------------------------------------------------------
-- KEYBINDINGS — focus with arrow keys (repeating)
-- Each pair also brings the newly-focused window to top (mirrors old bringactivetotop)
--------------------------------------------------------------------------------

hl.bind("SUPER + left", function()
  hl.dispatch(hl.dsp.focus({ direction = "left" }))
  hl.dispatch(hl.dsp.window.bring_to_top())
end, { repeating = true })

hl.bind("SUPER + right", function()
  hl.dispatch(hl.dsp.focus({ direction = "right" }))
  hl.dispatch(hl.dsp.window.bring_to_top())
end, { repeating = true })

hl.bind("SUPER + up", function()
  hl.dispatch(hl.dsp.focus({ direction = "up" }))
  hl.dispatch(hl.dsp.window.bring_to_top())
end, { repeating = true })

hl.bind("SUPER + down", function()
  hl.dispatch(hl.dsp.focus({ direction = "down" }))
  hl.dispatch(hl.dsp.window.bring_to_top())
end, { repeating = true })

--------------------------------------------------------------------------------
-- KEYBINDINGS — workspace navigation
--------------------------------------------------------------------------------

hl.bind("SUPER + escape", hl.dsp.focus({ last = true }))
hl.bind("SUPER + Backspace", hl.dsp.focus({ workspace = "prev" }))

-- SUPER + 1-9  → workspace 1-9
-- SUPER + 0    → workspace 0  (separate from 10)
-- SUPER+SHIFT + 1-9  → move to workspace 1-9 silently
-- SUPER+SHIFT + 0    → move to workspace 10 silently (matches old config intent)
local num_keys = {
  { key = "1", focus = 1, move = 1 },
  { key = "2", focus = 2, move = 2 },
  { key = "3", focus = 3, move = 3 },
  { key = "4", focus = 4, move = 4 },
  { key = "5", focus = 5, move = 5 },
  { key = "6", focus = 6, move = 6 },
  { key = "7", focus = 7, move = 7 },
  { key = "8", focus = 8, move = 8 },
  { key = "9", focus = 9, move = 9 },
  { key = "0", focus = 0, move = 10 },
}

for _, entry in ipairs(num_keys) do
  hl.bind("SUPER + " .. entry.key, hl.dsp.focus({ workspace = entry.focus }))
  hl.bind("SUPER + SHIFT + " .. entry.key, hl.dsp.window.move({ workspace = entry.move, silent = true }))
end

hl.bind("SUPER + F1", hl.dsp.focus({ workspace = 11 }))
hl.bind("SUPER + SHIFT + F1", hl.dsp.window.move({ workspace = 11, silent = true }))
hl.bind("SUPER + SHIFT + Backspace", hl.dsp.window.move({ workspace = "previous", silent = true }))

--------------------------------------------------------------------------------
-- KEYBINDINGS — mouse buttons
--------------------------------------------------------------------------------

-- Move / resize windows with SUPER + LMB / RMB
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- autostart.lua (or wherever you handle exec/startup)

-- Fire Thunderbird on workspace 4 at startup, one-shot rule
local thunderbird_handled = false

hl.on("window.open", function(w)
  if thunderbird_handled then return end

  if w.class:match("thunderbird") then
    thunderbird_handled = true
    -- Use hl.dispatch() to execute the dispatcher
    -- Use hl.dsp.window.move() (not hl.dsp.move)
    hl.dispatch(hl.dsp.window.move({ workspace = 4, window = w }))
  end
end)


hl.on("window.open", function(w)
    -- Only act on the currently active workspace so we do not pull focus
    -- from another monitor/workspace
    local active_ws = hl.get_active_workspace()
    if not active_ws or not w.workspace or w.workspace.id ~= active_ws.id then
        return
    end

    -- Get all actual windows on this workspace (layers are excluded)
    local windows = hl.get_workspace_windows(active_ws)

    -- If this newly opened window is the only one, force focus onto it
    if #windows == 1 then
        hl.dispatch(hl.dsp.focus({ window = w }))
    end
end)

hl.bind("SUPER + SHIFT + C", function()
  local w = hl.get_active_window()
  if w == nil then return end

  -- Check if the active window has the "dontclose" tag
  if w.tags then
    for _, tag in ipairs(w.tags) do
      if tag == "dontclose" then return end
    end
  end

  hl.dispatch(hl.dsp.window.close())
end)
