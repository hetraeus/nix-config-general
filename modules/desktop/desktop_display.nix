{ flake.homeModules.desktop_display = { pkgs, lib, self, config, ... }: {

home.packages = [
  pkgs.wdisplays
  self.packages.${pkgs.stdenv.hostPlatform.system}.visual-brightness
  ];

systemd.user.services.gammarelay = {
  Service.ExecStart = "${lib.getExe pkgs.wl-gammarelay-rs} run";
  Unit.Description  = "software change gamma and brightness";
  Unit.After        = [ "graphical-session.target" ] ;
  Unit.Wants        = [ "graphical-session.target" ] ;
  Install.WantedBy  = [ "graphical-session.target" ] ;
};

xdg.desktopEntries.invertColors = {
  name        = "☯ invert colors display";
  exec        = "${lib.getExe' pkgs.systemd "busctl"} --user call rs.wl-gammarelay / rs.wl.gammarelay ToggleInverted";
  terminal    = false;
  categories  = [ "Settings" ];
  genericName = "invert colors display";
  icon        = "invertimage";
  };

  # wayland.windowManager.hyprland.extraLuaFiles.display_support = let
  wayland.windowManager.hyprland.extraConfig = let
  run-or-raise = "${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.wrun-or-raise}" ;
  in ''
    hl.bind("SUPER + P", hl.dsp.exec_cmd("${run-or-raise} wdisplays ${lib.getExe pkgs.wdisplays}"))
    hl.permission({binary="${lib.getExe' pkgs.wdisplays ".wdisplays-wrapped"}", type="screencopy", mode="allow"})

    hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("visual-brightness down"), { repeating = true })
    hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("visual-brightness   up"), { repeating = true })
  '';

};}
