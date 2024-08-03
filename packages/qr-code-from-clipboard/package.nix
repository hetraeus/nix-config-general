{ perSystem = { pkgs, ... }: {
  packages.qr-code-from-clipboard = let
    script = pkgs.writeShellApplication {
      name          = "qr-code-from-clipboard";
      runtimeInputs = [
        pkgs.satty
        pkgs.kitty
        pkgs.coreutils
        pkgs.gnused
        pkgs.fzf
        pkgs.wl-clipboard-rs
        pkgs.zint-qt
      ];
      text = ''
        VIEWER="satty --default-hide-toolbars --filename -"
        case "''${1-other}" in
          window)       COMMAND="$VIEWER" ;;
          kitten)       COMMAND="kitten icat --transfer-mode=file --"        ;;
          kittenchoice) COMMAND="kitten icat --transfer-mode=file --"
            CODECHOICE=$(
            { zint --types | cut --characters=1-39
              zint --types | tail --lines=+2 | cut --characters=39- ;} \
            | sed -e 's/^ *[0-9]* *//;/^$/d' \
            | fzf --header-lines=1 --bind='enter:become:echo {1}')
            ;;
        esac
        zint                                \
        --data="$(wl-paste --primary)"      \
        --scalexdimdp=1,720dpi              \
        --barcode="''${CODECHOICE:-QRCODE}" \
        --secure=2                          \
        --bg=FFFFFF                         \
        --fg=000000                         \
        --filetype=PNG                      \
        --direct                            \
        | ''${COMMAND:-$VIEWER}
      '';
    };
    desktopItem = pkgs.makeDesktopItem {
      name        = "qr-code-clipboard-generator";
      desktopName = "󰐲  QR code clipboard generator";
      exec        = "qr-code-from-clipboard window";
      comment     = "clipboard QRCODE barcode creation";
      categories  = [ "Utility" ];
      icon        = "view-barcode-qr";
    };
  in pkgs.buildEnv {
    name  = "qr-code-from-clipboard-wrapper";
    paths = [ script desktopItem ];
    meta.mainProgram = "qr-code-from-clipboard";
  };
};}
