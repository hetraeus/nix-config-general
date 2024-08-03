{ flake.homeModules.desktop_accessibility = { pkgs, lib, self, ... }: {
  home.sessionVariables.KB_MAIN_MOD = "SUPER";

  home.packages = [
    self.packages.${pkgs.stdenv.hostPlatform.system}.wvkbd-start-stop
    pkgs.wl-kbptr # mouse control with keyboard
    ];

  xdg.desktopEntries.gfclick = {
    name        = "gfclick";
    exec        = "${lib.getExe pkgs.wl-kbptr} -o modes=tile,click";
    terminal    = false;
    categories  = [ "Utility" ];
    icon        = "keyboard";
    genericName = "virtual click";
    };

  wayland.windowManager.hyprland.extraConfig = ''
    hl.config({
      input = {
        sensitivity = 0,
        touchpad = {
          natural_scroll = true,
        },
      },
    })
    '';
};}
