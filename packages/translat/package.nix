{ perSystem = { pkgs, ... }: {
  packages.translat = pkgs.writeShellApplication {
    name          = "translat";
    runtimeInputs = [ pkgs.coreutils pkgs.translate-shell pkgs.libnotify pkgs.wl-clipboard-rs ];
    text = ''
      SOURCE_TEXT="$(wl-paste --primary --no-newline)"
      DESTINATION=$1
      LANG_DEST=$2
      #LANG_START=$3
      case $DESTINATION in
        tr_notify)
          notify-send --app-name="󰗊 translate" "''${SOURCE_TEXT:0:25}" "$(trans -no-ansi :"$LANG_DEST" "''${SOURCE_TEXT}"            \
          | tail --lines=+2                              \
          | fold --spaces --width=75)" --expire-time=20000
          ;;
        tr_clipboard)
          wl-copy -- "$(trans -no-ansi -brief :"$LANG_DEST" "$SOURCE_TEXT")"
          ;;
        tr_voice)
          ;;
        dict_notify)
          notify-send --app-name="󰗊 translate" "''${SOURCE_TEXT:0:25}" "$(trans -no-ansi :"$LANG_DEST" "''${SOURCE_TEXT}" -dictionary \
          | tail --lines=+2                              \
          | fold --spaces --width=75)" --expire-time=20000
          ;;
        dict_clipboard)
          wl-copy -- "$(trans -no-ansi :"$LANG_DEST" "$SOURCE_TEXT" -dictionary )"
          ;;
        dict_voice)
          ;;
      esac
    '';
  };
};}
