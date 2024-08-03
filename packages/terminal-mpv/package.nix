{ perSystem = { pkgs, lib, self',... }: let
  mpv = self'.packages.mpv; # TODO configure
  in {
  packages.terminal-mpv = pkgs.makeDesktopItem {
    noDisplay   = true;
    name        = "terminal-mpv";
    desktopName = "terminal-mpv";
    icon        = "mpv";
    exec        = "${lib.getExe pkgs.kitty} --app-id=terminal_media_player --title=tplayer ${lib.getExe mpv} -- %U";
    mimeTypes   = [ "image/x-tga" ];
  };
};}
