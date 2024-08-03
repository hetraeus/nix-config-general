{ flake.homeModules.desktop_screenshot = { pkgs, lib, config, self, ... }: let
  grimscreen = self.packages.${pkgs.stdenv.hostPlatform.system}.grimscreen;
  ocr-screen = self.packages.${pkgs.stdenv.hostPlatform.system}.ocr-screen;
in {

  home.packages = [ grimscreen ocr-screen ];
  programs.hyprshot.saveLocation = "${config.xdg.userDirs.pictures}/.private/shots";

  # used by the grimscreen scipt
  xdg.userDirs.extraConfig.SCREENSHOTS = "${config.programs.hyprshot.saveLocation}";

  xdg.desktopEntries.screenshots_dir = {
    name         = "Screenshot Directory";
    exec         = "${lib.getExe' pkgs.xdg-utils "xdg-open"} \"${config.xdg.userDirs.extraConfig.SCREENSHOTS}\"";
    terminal     = false;
    categories   = [ "Utility" ];
    genericName  = "screenshot folder";
    icon         = "gtk-directory";
    };

#  wayland.windowManager.hyprland.extraLuaFiles.grim_integration = ''
   wayland.windowManager.hyprland.extraConfig = ''
    hl.permission({binary="${lib.getExe pkgs.grim}", type="screencopy", mode="allow"})
    hl.bind("Print", hl.dsp.exec_cmd("${lib.getExe grimscreen}"))
    hl.bind("SHIFT + Print", hl.dsp.exec_cmd("${lib.getExe ocr-screen}"))
    '';

};}
