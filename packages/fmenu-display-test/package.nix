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
        ffplay -loglevel quiet -fs -autoexit -f lavfi -i "
          color=c=white:s=$DISPLAY_SIZE:d=5[w];
          color=c=red:s=$DISPLAY_SIZE:d=5[r];
          color=c=green:s=$DISPLAY_SIZE:d=5[g];
          color=c=blue:s=$DISPLAY_SIZE:d=5[b];
          color=c=black:s=$DISPLAY_SIZE:d=5[k];
          smptehdbars=s=$DISPLAY_SIZE:d=10[bars];
          testsrc2=s=$DISPLAY_SIZE:d=10[mov];
          [w][r][g][b][k][bars][mov]concat=n=7:v=1:a=0"

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
