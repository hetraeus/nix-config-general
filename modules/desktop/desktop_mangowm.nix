{ flake.homeModules.desktop_mangowm = { config, lib, pkgs, self, ... } : {

wayland.windowManager.mango = let
  big_floater = pkgs.writeShellApplication {
    name = "big_floater";
    runtimeInputs = [ pkgs.gnugrep ];
    text = ''
      mmsg -d togglefloating
      mmsg -f | grep --only-matching '0$' --quiet && exit
      mmsg -d resizewin,1700,1000
      mmsg -d 'centerwin'
    '';
  };
  toggle_monocle = pkgs.writeShellApplication {
    name = "toggle_monocle";
    runtimeInputs = [ pkgs.gawk ];
    text = ''
      LAYOUT="$(mmsg -g | awk '$2=="layout" {print $3}')"
      [[ "$LAYOUT" == "M" ]] && { mmsg -l "TG"; exit; }
      mmsg -l "M"
    '';
  };
in {
  enable   = true;
  settings = ''
exec=~/.config/mango/autostart.sh
# see config.conf
# More option see https://github.com/DreamMaoMao/mango/wiki/

# Window effect
blur=0
blur_layer=0
blur_optimized=1
blur_params_num_passes = 2
blur_params_radius = 5
blur_params_noise = 0.02
blur_params_brightness = 0.9
blur_params_contrast = 0.9
blur_params_saturation = 1.2

shadows = 0
layer_shadows = 0
shadow_only_floating = 1
shadows_size = 10
shadows_blur = 15
shadows_position_x = 0
shadows_position_y = 0
shadowscolor= 0x000000ff
# bindl

border_radius=4
no_radius_when_single=1
focused_opacity=1.0
unfocused_opacity=1.0
view_current_to_back=1

# Animation Configuration(support type:zoom,slide)
# tag_animation_direction: 0-horizontal,1-vertical
animations=1
layer_animations=1
animation_type_open=slide
animation_type_close=slide
animation_fade_in=1
animation_fade_out=1
tag_animation_direction=0
zoom_initial_ratio=0.3
zoom_end_ratio=0.8
fadein_begin_opacity=0.5
fadeout_begin_opacity=0.8
animation_duration_move=500
animation_duration_open=400
animation_duration_tag=350
animation_duration_close=0
animation_duration_focus=0
animation_curve_open=0.46,1.0,0.29,1
animation_curve_move=0.46,1.0,0.29,1
animation_curve_tag=0.46,1.0,0.29,1
animation_curve_close=0.08,0.92,0,1
animation_curve_focus=0.46,1.0,0.29,1
animation_curve_opafadeout=0.5,0.5,0.5,0.5
animation_curve_opafadein=0.46,1.0,0.29,1

# Scroller Layout Setting
scroller_structs=6
scroller_default_proportion=0.67
scroller_focus_center=0
scroller_prefer_center=0
edge_scroller_pointer_focus=1
scroller_default_proportion_single=1.0
scroller_proportion_preset=0.33,0.67,1.0

# Master-Stack Layout Setting
new_is_master=0
default_mfact=0.55
default_nmaster=1
smartgaps=0

# Overview Setting
hotarea_size=10
enable_hotarea=1
ov_tab_mode=0
overviewgappi=5
overviewgappo=30

# Misc
no_border_when_single=0
axis_bind_apply_timeout=100
focus_on_activate=1
idleinhibit_ignore_visible=0
sloppyfocus=1
warpcursor=1
focus_cross_monitor=0
focus_cross_tag=0
enable_floating_snap=0
snap_distance=30
cursor_size=24
drag_tile_to_tile=1
allow_tearing=1

# keyboard
repeat_rate=25
repeat_delay=600
numlockon=0
xkb_rules_layout=it,us

# Trackpad
# need relogin to make it apply
disable_trackpad=0
tap_to_click=1
tap_and_drag=1
drag_lock=1
trackpad_natural_scrolling=1
disable_while_typing=1
left_handed=0
middle_button_emulation=0
swipe_min_threshold=1

# mouse
# need relogin to make it apply
mouse_natural_scrolling=0

# Appearance
gappih=0
gappiv=0
gappoh=4
gappov=4
scratchpad_width_ratio=0.8
scratchpad_height_ratio=0.9
borderpx=4
rootcolor=0x201b14ff
bordercolor=0x444444ff
#focuscolor=0xc9b890ff
#overlaycolor=0x14a57cff
focuscolor=0x14a57cff
overlaycolor=0x8639e8ff
maximizescreencolor=0x89aa61ff
urgentcolor=0xad401fff
scratchpadcolor=0x516c93ff
globalcolor=0xb153a7ff

# layout support:
# tile,scroller,grid,deck,monocle,center_tile,vertical_tile,vertical_scroller
tagrule=id:1,layout_name:scroller
tagrule=id:2,layout_name:tile
tagrule=id:3,layout_name:tile
tagrule=id:4,layout_name:tile
tagrule=id:5,layout_name:tile
tagrule=id:6,layout_name:tile
tagrule=id:7,layout_name:tile
tagrule=id:8,layout_name:tgmix
tagrule=id:9,layout_name:tile

# Key Bindings
# key name refer to `xev` or `wev` command output
# mod keys name: super,ctrl,alt,shift,none

# reload config
# Comment bind=SUPER,r,reload_config

# menu and terminal
bind=SUPER,F2,spawn,rofi -modi drun -show drun -show-icons -theme ~/.config/rofi/themes/board.rasi
bind=SUPER,a,spawn,kitty

bind=SUPER+Alt,code:65,spawn,swaync-client --toggle-panel
# code:107 = Print
# lib.getExe doesn't work
bind=NONE,code:107,spawn_shell,systemctl --user restart grimscreen


bind=SUPER,z,spawn,copyq menu
bind=ALT,z,spawn_shell,mpc --host=$XDG_RUNTIME_DIR/mpd/socket --quiet toggle
bind=ALT,less,spawn_shell,mpc --host=$XDG_RUNTIME_DIR/mpd/socket --quiet next
bind=ALT,greater,spawn_shell,mpc --host=$XDG_RUNTIME_DIR/mpd/socket --quiet prev
# lib.getExe doesn't work
bind=SUPER,code:53,spawn,systemctl --user restart fmenu-emoticon
#   MouseBack hotkey-overlay-title="Pie menu" { spawn-sh "/nix/store/s1qrwbs9lw3g130dr0hs7jlkcg5xj3nd-kando-2.0.0/bin/kando --menu 'Main menu'"; }
#    MouseBack hotkey-overlay-title="Pie Menu" { spawn-sh "/nix/store/lzv9k2sdqp9d6my8hc1vgbk0lmc6qhj9-piemenu_launch/bin/piemenu_launch kb"; }

bind=SUPER,s,spawn,sbuku askme
bind=SUPER+SHIFT,s,spawn,sbuku clipboard

bindl=ALT,s,spawn,wpctl set-volume @DEFAULT_AUDIO_SINK@ 6%+ --limit 1.8
bindl=ALT,a,spawn,wpctl set-volume @DEFAULT_AUDIO_SINK@ 6%-
bindl=NONE,XF86AudioRaiseVolume,spawn,wpctl set-volume @DEFAULT_AUDIO_SINK@ 6%+ --limit 1.8
bindl=NONE,XF86AudioLowerVolume,spawn,wpctl set-volume @DEFAULT_AUDIO_SINK@ 6%-
bindl=NONE,XF86AudioMute,spawn,wpctl    set-mute @DEFAULT_AUDIO_SINK@   toggle
bindl=NONE,XF86AudioMicMute,spawn,wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle

bindl=NONE,XF86MonBrightnessUp,spawn,${lib.getExe   self.packages.${pkgs.stdenv.hostPlatform.system}.visual-brightness} up
bindl=NONE,XF86MonBrightnessDown,spawn,${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.visual-brightness} down

# exit
# bind=SUPER,m,quit
bind=SUPER+SHIFT,c,killclient

# switch window focus
bind=SUPER,Tab,focusstack,next
bind=SUPER+SHIFT,Tab,focusstack,prev
bind=SUPER,Left,focusdir,left
bind=SUPER,Right,focusdir,right
bind=SUPER,Up,focusdir,up
bind=SUPER,Down,focusdir,down
# basckspace
bind=SUPER,code:22,focuslast

# swap window
bind=SUPER+CTRL,Up,exchange_client,up
bind=SUPER+CTRL,Down,exchange_client,down
bind=SUPER+CTRL,Left,exchange_client,left
bind=SUPER+CTRL,Right,exchange_client,right

# switch window status
bind=SUPER,g,toggleglobal
bind=SUPER+CTRL,Tab,toggleoverview
bind=SUPER,f,spawn,${lib.getExe toggle_monocle}
bind=SUPER+ALT,f,spawn,${lib.getExe big_floater}
bind=SUPER+SHIFT,o,togglefloating
#bind=super,w,spawn,${lib.getExe config.programs.firefox.package} --new-tab

# Comment bind=ALT+SHIFT,a,togglemaximizescreen
bind=SUPER+SHIFT,f,togglefullscreen
bind=ALT+SHIFT,f,togglefakefullscreen
bind=SUPER,d,minimized
bind=SUPER,o,centerwin
bind=SUPER+SHIFT,y,toggleoverlay
bind=SUPER+SHIFT,d,restore_minimized
bind=SUPER+SHIFT,p,toggle_scratchpad

bind=SUPER,r,switch_proportion_preset

# scroller layout
# bind=ALT,e,set_proportion,1.0
# bind=ALT,x,switch_proportion_preset

# switch layout
# bind=SUPER,n,switch_layout

# tag switch
# Comment bind=SUPER,Left,viewtoleft,0
# Comment bind=CTRL,Left,viewtoleft_have_client,0
# Comment bind=SUPER,Right,viewtoright,0
# Comment bind=CTRL,Right,viewtoright_have_client,0
# Comment bind=CTRL+SUPER,Left,tagtoleft,0
# Comment bind=CTRL+SUPER,Right,tagtoright,0

bind=SUPER,1,view,1,0
bind=SUPER,2,view,2,0
bind=SUPER,3,view,3,0
bind=SUPER,4,view,4,0
bind=SUPER,5,view,5,0
bind=SUPER,6,view,6,0
bind=SUPER,7,view,7,0
bind=SUPER,8,view,8,0
bind=SUPER,9,view,9,0

# tag: move client to the tag and focus it
# tagsilent: move client to the tag and not focus it
# Comment bind=Alt,1,tagsilent,1
bind=SUPER+SHIFT,1,tagsilent,1,0
bind=SUPER+SHIFT,2,tagsilent,2,0
bind=SUPER+SHIFT,3,tagsilent,3,0
bind=SUPER+SHIFT,4,tagsilent,4,0
bind=SUPER+SHIFT,5,tagsilent,5,0
bind=SUPER+SHIFT,6,tagsilent,6,0
bind=SUPER+SHIFT,7,tagsilent,7,0
bind=SUPER+SHIFT,8,tagsilent,8,0
bind=SUPER+SHIFT,9,tagsilent,9,0

# monitor switch TEST bug
# bind=alt+shift,Left,focusmon,left
# bind=alt+shift,Right,focusmon,right
# bind=SUPER+Alt,Left,tagmon,left
# bind=SUPER+Alt,Right,tagmon,right

# gaps
# Comment bind=ALT+SHIFT,X,incgaps,1
# Comment bind=ALT+SHIFT,Z,incgaps,-1
# Comment bind=ALT+SHIFT,R,togglegaps

# movewin
bind=SUPER+SHIFT,Up,movewin,+0,-50
bind=SUPER+SHIFT,Down,movewin,+0,+50
bind=SUPER+SHIFT,Left,movewin,-50,+0
bind=SUPER+SHIFT,Right,movewin,+50,+0

# resizewin
bind=SUPER+SHIFT,code:35,resizewin,+0,+50
bind=SUPER+SHIFT,code:61,resizewin,+0,-50
bind=SUPER,code:35,resizewin,+50,+0
bind=SUPER,code:61,resizewin,-50,+0

# Mouse Button Bindings
# NONE mode key only work in ov mode
mousebind=SUPER,btn_left,moveresize,curmove
mousebind=SUPER,btn_right,moveresize,curresize
mousebind=NONE,btn_left,toggleoverview,1
mousebind=NONE,btn_right,killclient,0

# Axis Bindings
# Comment axisbind=SUPER,UP,viewtoleft_have_client
# Comment axisbind=SUPER,DOWN,viewtoright_have_client

# 3-finger swipe to move focus
gesturebind=none,left,3,focusdir,right
gesturebind=none,right,3,focusdir,left
gesturebind=none,top,3,focusdir,bottom
gesturebind=none,bottom,3,focusdir,top

# 4-finger swipe to switch workspace
gesturebind=none,up,4,viewtoright_have_client
gesturebind=none,down,4,viewtoleft_have_client

# layer rule
layerrule=animation_type_open:zoom,layer_name:rofi
layerrule=animation_type_close:zoom,layer_name:rofi

windowrule=width:450,height:700,offsety:27,offsetx:48,isfloating:1,isoverlay:1,animation_type_open:none,scroller_proportion:0.1,appid:com.github.hluk.copyq,title:CopyQ
windowrule=tags:2,appid:firefox
windowrule=isfloating:1,appid:xdg-desktop-portal-gtk
windowrule=scroller_proportion:1.0,appid:^(log|music|network)_dashboard$
windowrule=scroller_proportion:1.0,appid:java,title:Mindustry
windowrule=scroller_proportion:1.0,appid:thunderbird
windowrule=animation_type_open:zoom,appid:com.gabm.satty

'';
  systemd.xdgAutostart = true;
  systemd.variables = [
    "DISPLAY"
    "WAYLAND_DISPLAY"
    "XDG_CURRENT_DESKTOP=wlroots" # required by OBS
    "XDG_SESSION_TYPE"
    "NIXOS_OZONE_WL"
    "XCURSOR_THEME"
    "XCURSOR_SIZE"
    ];
  systemd.extraCommands = [
    "systemctl --user import-environment"
    "systemctl --user reset-failed"
    "systemctl --user start mango-session.target"
    ];
  autostart_sh = ''
# see autostart.sh
# Note: here no need to add shebang
'';
  };

xdg.desktopEntries.wm_vertical_tile = let exec_line = pkgs.writeShellScriptBin "exec_line" "mmsg -l 'VT'";
  in {
  name         = "wm_vertical_tile";
  genericName  = "mangowm vertical tiling master layout";
  icon         = "horizontal";
  terminal     = false;
  categories   = [ "Utility" ];
  exec         = "${lib.getExe exec_line}";
  };

xdg.desktopEntries.wm_master_left = let exec_line = pkgs.writeShellScriptBin "exec_line" "mmsg -l 'T'";
  in {
  name         = "wm_master_left";
  genericName  = "mangowm tiling left master layout";
  icon         = "window-symbolic";
  terminal     = false;
  categories   = [ "Utility" ];
  exec         = "${lib.getExe exec_line}";
  };

xdg.desktopEntries.wm_master_right = let exec_line = pkgs.writeShellScriptBin "exec_line" "mmsg -l 'RT'";
  in {
  name         = "wm_master_right";
  genericName  = "mangowm tiling right master layout";
  icon         = "window-symbolic";
  terminal     = false;
  categories   = [ "Utility" ];
  exec         = "${lib.getExe exec_line}";
  };

xdg.desktopEntries.wm_vertical_scroller = let exec_line = pkgs.writeShellScriptBin "exec_line" "mmsg -l 'VS'";
  in {
  name         = "wm_vertical_scroller";
  genericName  = "mangowm vertical tiling scroller layout";
  icon         = "horizontal";
  terminal     = false;
  categories   = [ "Utility" ];
  exec         = "${lib.getExe exec_line}";
  };

xdg.desktopEntries.wm_scroller = let exec_line = pkgs.writeShellScriptBin "exec_line" "mmsg -l 'S'";
  in {
  name         = "wm_scroller";
  genericName  = "mangowm tiling scroller layout";
  icon         = "window-restore";
  terminal     = false;
  categories   = [ "Utility" ];
  exec         = "${lib.getExe exec_line}";
  };

xdg.desktopEntries.wm_grid = let exec_line = pkgs.writeShellScriptBin "exec_line" "mmsg -l 'TG'";
  in {
  name         = "wm_grid";
  genericName  = "mangowm tiling grid layout";
  icon         = "grid-rectangular";
  terminal     = false;
  categories   = [ "Utility" ];
  exec         = "${lib.getExe exec_line}";
  };

xdg.desktopEntries.wm_monocle_fullscreen = let exec_line = pkgs.writeShellScriptBin "exec_line" "mmsg -l 'M'";
  in {
  name         = "wm_monocle_fullscreen";
  genericName  = "mangowm monocle fullscreen layout";
  icon         = "view-fullscreen";
  terminal     = false;
  categories   = [ "Utility" ];
  exec         = "${lib.getExe exec_line}";
  };

xdg.desktopEntries.wm_deck = let exec_line = pkgs.writeShellScriptBin "exec_line" "mmsg -l 'K'";
  in {
  name         = "wm_deck";
  genericName  = "mangowm deck layout";
  icon         = "view-fullscreen";
  terminal     = false;
  categories   = [ "Utility" ];
  exec         = "${lib.getExe exec_line}";
  };

xdg.desktopEntries.wm_master_plus = let exec_line = pkgs.writeShellScriptBin "exec_line" "mmsg -d incnmaster,+1";
  in {
  name         = "wm_master_plus";
  genericName  = "add master mangowm";
  icon         = "view-fullscreen";
  terminal     = false;
  categories   = [ "Utility" ];
  exec         = "${lib.getExe exec_line}";
  };


xdg.desktopEntries.wm_master_minus = let exec_line = pkgs.writeShellScriptBin "exec_line" "mmsg -d incnmaster,-1";
  in {
  name         = "wm_master_minus";
  genericName  = "remove master mangowm";
  icon         = "view-fullscreen";
  terminal     = false;
  categories   = [ "Utility" ];
  exec         = "${lib.getExe exec_line}";
  };

xdg.desktopEntries.wm_pin_floating = let exec_line = pkgs.writeShellScriptBin "exec_line" "mmsg -d togglefloating; mmsg -d toggleoverlay; mmsg -d toggleglobal";
  in {
  name         = "wm_pin_floating";
  genericName  = "global floating overlay mangowm";
  icon         = "pin";
  terminal     = false;
  categories   = [ "Utility" ];
  exec         = "${lib.getExe exec_line}";
  };

};}
