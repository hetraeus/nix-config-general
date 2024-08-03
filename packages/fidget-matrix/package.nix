{ perSystem = { lib, pkgs, ... }: let
    fidget = "${lib.getExe pkgs.tmatrix} --title=\" \" --background=\"default\" --steps-per-sec=9";
  in {
  packages.fidget-tmatrix = let
    script = pkgs.writeShellApplication {
      name = "tmatrix";
      text = ''echo -en "\033]0;カ tmatrix\007"; ${fidget}'';
      };
    desktopItem = pkgs.makeDesktopItem {
      name           = "tmatrix";
      exec           = "${lib.getExe pkgs.kitty} --title=\"カ tmatrix\" ${fidget}";
      desktopName    = "cmatrix screensaver";
      genericName    = "cmatrix screensaver";
      categories     = [ "Game" ];
      terminal       = false;
      icon           = "text_letter_spacing";
      };
  in pkgs.buildEnv {
    name             = "tmatrix-wrapper";
    paths            = [ script desktopItem ];
    meta.mainProgram = "tmatrix";
  };
};}
