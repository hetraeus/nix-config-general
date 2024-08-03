{ perSystem = { pkgs, ... }: {
  packages.wvkbd-start-stop = let
    script = pkgs.writeShellApplication {
      name          = "wvkbd-start-stop";
      runtimeInputs = [ pkgs.wvkbd pkgs.procps pkgs.nerd-fonts.iosevka ];
      text = ''
        OPACITY=84
        # WARN: don't change these, you don't need stylix EVERYWHERE
        BGCOLOR='#403077'
        FONT="Iosevka NFM 30"
        pkill -SIGRTMIN wvkbd-mobintl ||
          wvkbd-mobintl --fn "$FONT" -L 270 --bg "''${BGCOLOR#\#}$OPACITY" & disown
      '';
    };
    desktopItem = pkgs.makeDesktopItem {
      name        = "wvkbd";
      exec        = "wvkbd-start-stop";
      genericName = "virtual keyboard";
      desktopName = "virtual keyboard";
      categories  = [ "Utility" ];
      icon        = "keyboard";
    };
  in pkgs.buildEnv {
    name  = "wvkbd-start-stop-wrapper";
    paths = [ script desktopItem ];
    meta.mainProgram = "wvkbd-start-stop";
  };
};}
