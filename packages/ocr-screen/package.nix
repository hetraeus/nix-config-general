{ perSystem = { pkgs, ... }: {
  packages.ocr-screen = let
    script = pkgs.writeShellApplication {
      name          = "ocr-screen";
      text          = builtins.readFile ./ocr-screen;
      runtimeInputs = [
        pkgs.coreutils
        pkgs.grim
        pkgs.imagemagick
        pkgs.libnotify
        pkgs.translate-shell
        pkgs.slurp
        pkgs.tesseract
        pkgs.wl-clipboard-rs
      ];
    };
    desktopItem = pkgs.makeDesktopItem {
      name        = "ocr-screen";
      exec        = "ocr-screen";
      comment     = "clipboard QRCODE barcode creation";
      desktopName = "OCR word phrases recognition";
      genericName = "OCR word phrases recognition";
      categories  = [ "Utility" ];
      icon        = "mail-thread-watch";
    };
  in pkgs.buildEnv {
    name             = "ocr-screen-wrapper";
    paths            = [ script desktopItem ];
    meta.mainProgram = "ocr-screen";
  };
};}
