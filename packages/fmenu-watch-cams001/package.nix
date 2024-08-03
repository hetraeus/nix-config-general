{ perSystem = { pkgs, lib, config, ... }: {
  options.fmenu-watch-cams001.watchCamsPath = lib.mkOption {
    type    = lib.types.str;
    default = "$XDG_RUNTIME_DIR/watch-cams001";
    description = "Path to the file containing camera URLs.";
  };

  config.packages.fmenu-watch-cams0001 = let
    script = pkgs.writeShellApplication {
      name          = "fmenu-watch-cams001";
      runtimeInputs = [ pkgs.mpv ];
      text = ''
        command -v mmsg >/dev/null && mmsg -t 8
        while IFS= read -r CAM; do
          mpv                          \
          --wayland-app-id=securitycam \
          --x11-name=securitycam       \
            "$CAM" 2>/dev/null & disown
         done < "${config.fmenu-watch-cams001.watchCamsPath}"
         unset CAMS
      '';
    };

    desktopItem = pkgs.makeDesktopItem {
      name         = "fmenu-watch-cams001";
      genericName  = "webcams watch";
      desktopName  = "webcams watch";
      icon         = "camera-ready";
      terminal     = false;
      categories   = [ "Utility" ];
      exec         = "fmenu-watch-cams001";
      };

  in pkgs.buildEnv {
    name  = "fmenu-watch-cams001-wrapper";
    paths = [ script desktopItem ];
    meta.mainProgram = "fmenu-watch-cams001";
  };
};}
