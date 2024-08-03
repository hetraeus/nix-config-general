{ perSystem = { pkgs, lib, ... }: {
  packages.cam-reader = let
    script = pkgs.writeShellApplication {
      name          = "cam-reader";
      runtimeInputs = [ pkgs.zbar pkgs.wl-clipboard-rs ];
      text = ''
        zbarcam | while read -r barcode; do
          wl-copy "''${barcode##QR-Code:}"
          notify-send "Copied" "''${barcode##QR-Code:}"
        done
      '';
    };
    desktopItem = pkgs.makeDesktopItem {
      desktopName = "󰐲  QR Code barcode zbar 📸cam";
      exec        = "cam-reader";
      name        = "cam-reader";
      comment     = "Read QR codes from camera and copy to clipboard Aztec QRCODE barcode webcam";
      categories  = [ "Utility" ];
      icon        = "view-barcode-qr";
    };
  in pkgs.buildEnv {
    name  = "cam-reader-wrapper";
    paths = [ script desktopItem ];
    meta.mainProgram = "cam-reader";
  };
};}
