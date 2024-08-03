{ perSystem = { lib, pkgs, ... }: let
    fidget = "${lib.getExe pkgs.terminal-rain-lightning} --sound --volume normal --speed medium";
  in {
  packages.fidget-rain = let
    script = pkgs.writeShellApplication {
      name = "terminal-rain";
      text = ''echo -en "\033]0;🌧  terminal-rain\007"; ${fidget}'';
      };
    desktopItem = pkgs.makeDesktopItem {
      name           = "terminal-rain";
      exec           = "${lib.getExe pkgs.kitty} --title=\"🌧  terminal-rain\" ${fidget}";
      genericName    = "ambient thunderstorm cozy";
      desktopName    = "ambient thunderstorm cozy";
      icon           = "weather-freezing-rain";
      categories     = [ "Game" ];
      terminal       = false;
      };
  in pkgs.buildEnv {
    name             = "fidget-rain-wrapper";
    paths            = [ script desktopItem ];
    meta.mainProgram = "fidget-rain";
  };
};}
