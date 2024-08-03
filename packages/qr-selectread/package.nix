{ perSystem = { pkgs, ... }: {
  packages.qr-selectread = let
    script = pkgs.writeShellApplication {
      name          = "qr-selectread";
      runtimeInputs = [
        pkgs.slurp pkgs.zbar pkgs.grim pkgs.imagemagick
        pkgs.coreutils pkgs.libnotify pkgs.wl-clipboard-rs
      ];
      text = ''
        TMP_SCREENSHOT="$XDG_RUNTIME_DIR"/zbar-"$(date --iso-8601)".png
        slurp  -b '#0000ff00' -c '#ff0000ff' \
        | grim -g - "$TMP_SCREENSHOT"
        # magick      "$TMP_SCREENSHOT"  \
        # -set colorspace Gray           \
        # -separate                      \
        # -evaluate-sequence Mean        \
        # -scale 300%                    \
        # -sharpen 0x3                   \
        # "$TMP_SCREENSHOT".png
        scanresult="$(zbarimg --quiet --raw "$TMP_SCREENSHOT" | tr --delete '\n')"
        rm "$TMP_SCREENSHOT" #{,.png}
        [ -z "$scanresult" ] && { notify-send --app-name="$0" "󰐲 (no read)"; exit; }
        wl-copy           <<< "$scanresult"
        wl-copy --primary <<< "$scanresult"
        notify-send               \
        --app-name="$0"           \
          "󰐲 Copied to clipboard" \
          "$scanresult"
      '';
    };
    desktopItem = pkgs.makeDesktopItem {
      exec        = "qr-selectread";
      desktopName = "󰐲  barcode zbar 🖵 screen";
      name        = "qr-selectread";
      comment     = "Read QR codes from selection on screen Aztec QRCODE barcode webcam";
      categories  = [ "Utility" ];
      icon        = "view-barcode-qr";
    };
  in pkgs.buildEnv {
    name  = "qr-selectread-wrapper";
    paths = [ script desktopItem ];
    meta.mainProgram = "qr-selectread";
  };
};}
