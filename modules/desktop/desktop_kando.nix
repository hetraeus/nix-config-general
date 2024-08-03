{ flake.homeModules.desktop_kando = { pkgs, lib, self, ... }: {
  home.packages = [
    self.packages.${pkgs.stdenv.hostPlatform.system}.hyprnotipick
    pkgs.gcolor3
    pkgs.playerctl
    ];

  xdg.autostart.entries = lib.singleton (
    pkgs.makeDesktopItem {
      name = "kando";
      desktopName = "kando";
      exec = "${lib.getExe pkgs.kando}";
      } + /share/applications/kando.desktop
    );
 xdg.mimeApps.defaultApplications = { "x-scheme-handler/kando"= [ "kando.desktop" ]; };

};}
