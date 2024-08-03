{ perSystem = { pkgs, self', ... }: {
  packages.mouse-pos = pkgs.writeShellApplication {
    name          = "mouse-pos";
    runtimeInputs = [ self'.packages.wdotool self'.packages.wl-find-cursor ];
    text          = ''
      wl-find-cursor &
      WFC_PID=$!
      wdotool mousemove --relative 0  1 2>/dev/null
      wdotool mousemove --relative 0 -1 2>/dev/null
      wait $WFC_PID
      '';
  };
};}
