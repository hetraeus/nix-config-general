{ perSystem = { lib, pkgs, ... }: let
    fidget = "${lib.getExe pkgs.tty-clock} -c -C7 -n -s";
  in {
  packages.fidget-tty-clock = let
    script = pkgs.writeShellScriptBin "tty-clock" ''
      echo -en "\033]0;🕓 tty-clock\007"; ${fidget}
      '';
    desktopItem = pkgs.makeDesktopItem {
      name           = "tty-clock";
      exec           = "${lib.getExe pkgs.kitty} --title=\"🕓 tty-clock\" ${fidget}";
      genericName    = "watch";
      desktopName    = "watch";
      icon           = "clock-large";
      categories     = [ "Game" ];
      terminal       = false;
      };
  in pkgs.buildEnv {
    name             = "tty-clock-wrapper";
    paths            = [ script desktopItem ];
    meta.mainProgram = "tty-clock";
  };
};}
