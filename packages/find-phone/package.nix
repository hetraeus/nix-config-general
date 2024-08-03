{ perSystem = { lib, pkgs, ... }: {
  packages.find-phone =  pkgs.makeDesktopItem {
    name         = "find-phone";
    exec         = "${pkgs.xdg-utils}/bin/xdg-open https://www.google.com/android/find";
    terminal     = false;
    categories   = [ "Network" ];
    genericName  = "Google find Android position";
    desktopName  = "track Google Android";
    icon         = "smartphone";
    };
};}
