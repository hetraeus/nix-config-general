{ perSystem = { lib, pkgs, ... }: let
    fidget = "${lib.getExe pkgs.tetris} --level 0";
  in {
  packages.fidget-tetris = let
    script = pkgs.writeShellApplication {
      name = "tetris";
      text = ''echo -en "\033]0;⠶ tetris\007"; ${fidget}'';
      };
    desktopItem = pkgs.makeDesktopItem {
      name           = "tetris";
      exec           = "${lib.getExe pkgs.kitty} --title=\"⠶ tetris\" ${fidget}";
      desktopName    = "tetris";
      genericName    = "blocks";
      categories     = [ "Game" ];
      terminal       = false;
      icon           = "blockdevice";
      };
  in pkgs.buildEnv {
    name             = "tetris-wrapper";
    paths            = [ script desktopItem ];
    meta.mainProgram = "tetris";
  };
};}
