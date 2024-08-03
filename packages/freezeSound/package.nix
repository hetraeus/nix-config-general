{ perSystem = { pkgs, lib, ... }: {
  packages.freeze-sound = let
    script = pkgs.writeShellApplication {
      name = "freezeSound";
      text = ''
        ${lib.getExe pkgs.playerctl} --all-players pause # INFO: this may affect mpd too because of mpris plugin
        MPD_HOST="$XDG_RUNTIME_DIR/mpd/socket"
        mpc --host="$MPD_HOST" --quiet pause> /dev/null  2>&1
      '';
    };
  in pkgs.makeDesktopItem {
    name        = "freeze-sound";
    desktopName = "Freeze Sound Music Shut Audio";
    exec        = "${lib.getExe script}";
    terminal    = false;
    categories  = [ "AudioVideo" ];
    icon        = "media-playback-pause";
  };
};}
