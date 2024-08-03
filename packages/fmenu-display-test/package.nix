{ perSystem = { pkgs, self', ... }: {
  packages.fmenu-display-test = let
    script = pkgs.writeShellApplication {
      name          = "fmenu-display-test";
      runtimeInputs = [
        pkgs.ffmpeg pkgs.jq pkgs.wlr-randr
        self'.packages.wdotool ];
      text = ''
        DISPLAY_SIZE="$(
          wlr-randr  --json \
          | jq --raw-output '
            .[].modes.[]
            | select (.current == true)
            | {width,height}
            | join("x")
            ')"
        wdotool mousemove --relative 12000 12000
        ffplay -loglevel quiet -fs -crf 0 -f lavfi -autoexit -i "
            color=c=#ffffff:d=25:s=$DISPLAY_SIZE,sendcmd='
          5 color c #ff0000;
         10 color c #00ff00;
         15 color c #0000ff;
         20 color c #000000
        '"
        wdotool mousemove --relative -100 -100
      '';
    };
    desktopItem = pkgs.makeDesktopItem {
      name        = "fmenu-display-test";
      desktopName = "Check the display for shut off pixels and dirt";
      exec        = "fmenu-display-test";
      terminal    = false;
      categories  = [ "Utility" ];
      icon        = "display";
    };
  in pkgs.buildEnv {
    name  = "fmenu-display-test-wrapper";
    paths = [ script desktopItem ];
    meta.mainProgram = "fmenu-display-test";
  };
};}
