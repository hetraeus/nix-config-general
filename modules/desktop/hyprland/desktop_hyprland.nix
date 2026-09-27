{ flake.homeModules.desktop_hyprland = { config, lib, pkgs, self, ... }: let

  piemenu_launch = self.legacyPackages.${pkgs.stdenv.hostPlatform.system}.piemenu-launchWith {
    piemenu-launch.base01 = "${config.lib.stylix.colors.withHashtag.base01}";
    piemenu-launch.base0D = "${config.lib.stylix.colors.withHashtag.base0D}";
    };

  run_or_raise         = "${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.wlr-focus}";
  skup                 = self.packages.${pkgs.stdenv.hostPlatform.system}.skup;
  hypr_hide_floats     = self.packages.${pkgs.stdenv.hostPlatform.system}.hypr-hide-floats;
  rasi_theme           = pkgs.writeTextFile { name = "rasi_theme"; text = builtins.readFile ../board.rasi ; };

  hypr_single_hide     = ''
    function()
      local w = hl.get_active_window()
      if not w then return end

      local ws = hl.get_active_workspace()
      if not ws or ws.name:match("^special:") then return end
      if not w.floating then return end

      hl.dispatch(hl.dsp.window.move({
          workspace = "special:" .. ws.name,
          follow = false,
          window = w
      }))
    end '';


in {

  home.packages = [ piemenu_launch ];
  wayland.windowManager.hyprland =      {
    enable                       =  true;
    xwayland.enable              =  true;
    systemd.enableXdgAutostart   =  true;

    # WARN: official hyprland documentation states that systemd home manager integration conflicts with the improved programs.hyprland.withUWSM systemd integration, so disable it
    systemd.enable               = true;

    };

  # wayland.windowManager.hyprland.extraLuaFiles.main = ./main.lua;
  # wayland.windowManager.hyprland.extraLuaFiles.floating = ./floating.lua;

  wayland.windowManager.hyprland.extraConfig =
#    builtins.readFile ./floating.lua +
    builtins.readFile ./main.lua +
    ''
    hl.bind("mouse:275", function()
      local cursor = hl.get_cursor_pos()
      local cmd = string.format(
        "CLIPBOARD_X=%d CLIPBOARD_Y=%d %s kb", 
        math.floor(cursor.x), 
        math.floor(cursor.y), 
        "${lib.getExe piemenu_launch}"
      )
      hl.dispatch(hl.dsp.exec_cmd(cmd))
    end , { mouse = true })

    hl.bind("mouse:276", function()
      local cursor = hl.get_cursor_pos()
      local cmd = string.format(
        "CLIPBOARD_X=%d CLIPBOARD_Y=%d %s wm",
        math.floor(cursor.x),
        math.floor(cursor.y),
        "${lib.getExe piemenu_launch}"
      )
      hl.dispatch(hl.dsp.exec_cmd(cmd))
    end , { mouse = true })


    hl.bind("SUPER + Z", function()
      local cursor = hl.get_cursor_pos()
      local cmd = string.format(
        "busctl --user call org.clipboard.Manager / org.clipboard.Manager Show ii %d %d",
        math.floor(cursor.x), math.floor(cursor.y))
      hl.dispatch(hl.dsp.exec_cmd(cmd))
    end)

    hl.bind("SUPER + S"        , hl.dsp.exec_cmd("${lib.getExe skup}     askme"))
    hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("${lib.getExe skup} clipboard"))

    hl.bind("ALT + SHIFT + D", hl.dsp.exec_cmd("${run_or_raise} songrec songrec"))

    hl.bind("SUPER + ALT + Space", hl.dsp.exec_cmd("noctalia msg panel-open control-center notifications"))
    hl.bind("SUPER + X",           hl.dsp.exec_cmd("${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.fmenu-emoticon}"))

    hl.bind("SUPER + ALT + D", dofile("${hypr_hide_floats}"))
    hl.bind("SUPER + D",               ${hypr_single_hide}  )

    hl.bind("SUPER + CONTROL + Tab",
      hl.dsp.exec_cmd("${lib.getExe pkgs.rofi} -show window -window-thumbnail -show-icons -window-format '{t}' -theme ${rasi_theme}"))
    hl.bind("SUPER + SHIFT + A", hl.dsp.exec_cmd("${lib.getExe pkgs.kitty}", { float = true, size = "1000 500" }))

    hl.bind("SUPER + Return", hl.dsp.exec_cmd("${lib.getExe pkgs.kitty}"))
    hl.bind("SUPER + A", hl.dsp.exec_cmd("${lib.getExe pkgs.kitty}"))
    hl.bind("SUPER + W", hl.dsp.exec_cmd("${run_or_raise} firefox firefox"))
    hl.bind("SUPER + Q", hl.dsp.exec_cmd("${run_or_raise} thunderbird thunderbird"))
    hl.bind("SUPER + N", function()
      hl.dispatch(hl.dsp.exec_cmd("thunderbird -calendar"))
      hl.dispatch(hl.dsp.focus({ window = "class:thunderbird" }))
    end)

    hl.bind("SUPER + F2", hl.dsp.exec_cmd("noctalia msg panel-open launcher"))
    -- hl.bind("SUPER + CONTROL + Z", hl.dsp.exec_cmd("fmenu-text-style"))
    hl.bind("SUPER + Space", hl.dsp.exec_cmd("${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.hyprmenu-launch}"))

    '';


  xdg.desktopEntries.hyprMagnifier = let
    hyprMagnifier = pkgs.writeShellApplication {
      name = "hyprMagnifier";
      runtimeInputs = [ pkgs.hyprland ];
      text = ''
        hyprctl eval 'local current = hl.get_config("cursor.zoom_factor")
        hl.config({ cursor = { zoom_factor = 3.0 - current } })'
        '';};
   in {
    name        = "magnifier";
    exec        = "${lib.getExe hyprMagnifier}";
    terminal    = false;
    categories  = [ "Settings" ];
    genericName = "zoom enhance magnifier";
    icon        = "zoom-in";
    };
};}
