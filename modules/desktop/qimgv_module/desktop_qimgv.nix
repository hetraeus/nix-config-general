{ flake.homeModules.desktop_qimgv = { lib, ... }: {

  imports = [ ../_qimgv.nix ];

  programs.qimgv.enable = true;
  programs.qimgv = {
    backgroundFullscreenColor = "#000000";
    backgroundColor           = "#000000";
    };
  programs.qimgv.settings.General.useSystemColorScheme=true;
  programs.qimgv.settings.Controls = {
    shortcuts = builtins.concatStringsSep ", " [
      "jumpToFirst=Home" "nextImage=<"
      "jumpToLast=End"   "prevImage=>"

      "scrollDown=Down" "scrollUp=Up" "scrollLeft=Left" "scrollRight=Right"

      "contextMenu=Alt+X" "contextMenu=RMB" "contextMenu=Menu"

      "toggleFitMode=Space"
      "zoomOutCursor=WheelDown"
      "zoomInCursor=WheelUp"
      "zoomIn=]"   "zoomIn=Ctrl+]" "zoomIn=eq" "zoomIn=Ctrl+eq" # TEST zoom is working?
      "zoomOut=/" "zoomOut=Ctrl+/"

      "toggleFullscreenInfoBar=Shift+F"
      "toggleImageInfo=I"

      "moveToTrash=Del"    "removeFile=Shift+Del"

      "toggleFullscreen=F" "toggleFullscreen=F11" "toggleFullscreen=LMB_DoubleClick"
      "closeFullScreenOrExit=Q"

      "folderView=Backspace"

      "save=Ctrl+S"   "saveAs=Ctrl+Shift+S"
      "renameFile=F2" "reloadImage=F5"
      "moveFile=M"
      "open=Ctrl+O"

      "discardEdits=Ctrl+Z"
      "print=Ctrl+P"

      "seekVideoBackward=Ctrl+Left" "seekVideoForward=Ctrl+Right"

      "rotateLeft=Ctrl+Left" "rotateRight=Ctrl+Right"
      "copyFileClipboard=Ctrl+C"
      "copyPathClipboard=Ctrl+Shift+C"
      "pasteFile=Ctrl+V"

      "resize=R"
      "flipV=V"
      "flipH=H"
      "crop=X"

      ];
  };

  xdg.mimeApps.defaultApplications = let
    default_viewer = "qimgv.desktop";
    viewerMimeTypes = [
      "image/bmp"
      "image/gif"
      "image/jpeg"
      "image/png"
      "image/tiff"
      "image/webp"
      "image/heic"
      ];
    in lib.genAttrs viewerMimeTypes (_: [ default_viewer ]);

};}
