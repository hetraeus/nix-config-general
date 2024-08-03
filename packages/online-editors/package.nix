{ perSystem = { pkgs, lib, ... }: {
  packages.online-editors = let
    sumo3d = pkgs.makeDesktopItem {
      name        = "sumo3d";
      desktopName = "Sumo 3D";
      exec        = "${lib.getExe' pkgs.xdg-utils "xdg-open"} https://sumo.app/sumo3d";
      terminal    = false;
      categories  = [ "Graphics" "3DGraphics" ];
      genericName = "modelling editor";
      icon        = "model-x3d";
    };
    sumocode = pkgs.makeDesktopItem {
      name        = "sumocode";
      desktopName = "Sumo Code";
      exec        = "${lib.getExe' pkgs.xdg-utils "xdg-open"} https://sumo.app/sumocode";
      terminal    = false;
      categories  = [ "Utility" "TextEditor" ];
      genericName = "javascript text editor for games";
      icon        = "heroic-game-launcher";
    };
    sumovideo = pkgs.makeDesktopItem {
      name        = "sumovideo";
      desktopName = "Sumo Video";
      exec        = "${lib.getExe' pkgs.xdg-utils "xdg-open"} https://sumo.app/sumovideo";
      terminal    = false;
      categories  = [ "AudioVideoEditing" "Video" "AudioVideo" ];
      genericName = "NLVE NLE editor";
      icon        = "videotrimmer";
    };
    sumotunes = pkgs.makeDesktopItem {
      name        = "sumotunes";
      desktopName = "Sumo Tunes";
      exec        = "${lib.getExe' pkgs.xdg-utils "xdg-open"} https://sumo.app/sumotunes";
      terminal    = false;
      categories  = [ "AudioVideoEditing" "Audio" "AudioVideo" ];
      genericName = "sequencer editor";
      icon        = "sequeler";
    };
    sumoaudio = pkgs.makeDesktopItem {
      name        = "sumoaudio";
      desktopName = "Sumo Audio";
      exec        = "${lib.getExe' pkgs.xdg-utils "xdg-open"} https://sumo.app/sumoaudio";
      terminal    = false;
      categories  = [ "AudioVideoEditing" "Audio" "AudioVideo" ];
      genericName = "audio editor";
      icon        = "audio-recorder";
    };
    sumopixel = pkgs.makeDesktopItem {
      name        = "sumopixel";
      desktopName = "Sumo Pixel";
      exec        = "${lib.getExe' pkgs.xdg-utils "xdg-open"} https://sumo.app/sumopixel";
      terminal    = false;
      categories  = [ "Graphics" ];
      genericName = "drawing images pictures pixel art";
      icon        = "pixelart-trace";
    };
    sumopaint = pkgs.makeDesktopItem {
      name        = "sumopaint";
      desktopName = "Sumo Paint";
      exec        = "${lib.getExe' pkgs.xdg-utils "xdg-open"} https://sumo.app/sumopaint";
      terminal    = false;
      categories  = [ "Graphics" ];
      genericName = "drawing images pictures";
      icon        = "gnome-paint";
    };
    sumophoto = pkgs.makeDesktopItem {
      name        = "sumophoto";
      desktopName = "Sumo Photo";
      exec        = "${lib.getExe' pkgs.xdg-utils "xdg-open"} https://sumo.app/sumophoto";
      terminal    = false;
      categories  = [ "Graphics" ];
      genericName = "drawing images pictures";
      icon        = "photo";
    };
    photopea = pkgs.makeDesktopItem {
      name        = "photopea";
      desktopName = "Photopea";
      exec        = "${lib.getExe' pkgs.xdg-utils "xdg-open"} https://www.photopea.com/";
      terminal    = false;
      categories  = [ "Graphics" ];
      genericName = "drawing images pictures";
      icon        = "photo";
    };
    excalidraw = pkgs.makeDesktopItem {
      name        = "Excalidraw";
      desktopName = "Excalidraw";
      exec        = "${lib.getExe' pkgs.xdg-utils "xdg-open"} https://excalidraw.com/";
      terminal    = false;
      categories  = [ "Graphics" ];
      genericName = "Diagrams mind maps";
      icon        = "minder";
    };
  in pkgs.symlinkJoin {
    name  = "online-editors";
    paths = [ sumo3d sumocode sumopixel sumophoto sumoaudio sumotunes sumopaint sumovideo photopea excalidraw ];
  };
};}
