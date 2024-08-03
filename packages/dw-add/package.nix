{ perSystem = { pkgs, self', ... }: {
  packages.dw-add = pkgs.writeShellApplication {
    name          = "dw-add";
    runtimeInputs = [
      pkgs.kitty
      pkgs.libnotify
      pkgs.wl-clipboard-rs
      pkgs.apkeep
      pkgs.zenity
      self'.packages.dwaria
      self'.packages.yt-dl-presets
    ];
    text = ''
      DESTINATION_DIR="''${1/#\~\//$HOME/}"
      shift 1
      if [[ "$DESTINATION_DIR" == "choose_dest" ]]; then
        DESTINATION_DIR="$(zenity --file-selection --directory)"
        [[   -z "$DESTINATION_DIR" ]] && notify-send --app-name="''${0##*/}" '🔽 not downloading !'                 "$@" && exit
        [[ ! -w "$DESTINATION_DIR" ]] && notify-send --app-name="''${0##*/}" '❌ cannot write here !' "$DESTINATION_DIR" && exit
      fi
      KITTY_GROUP="Download"
      CLIPBOARD=""
      [[ "$*" == "CLIPBOARD" ]] && { CLIPBOARD="$(wl-paste)"; shift; }
      for remoteReference in "$@" "$CLIPBOARD"; do
        [[ "$remoteReference" == "" ]] && continue
        if [[ "$remoteReference" =~ ^magnet:    && ! -f "$remoteReference" ]] ||
           [[ "$remoteReference" =~ \.torrent$  ]]                            ||
           [[ "$remoteReference" =~ \.metalink$ ]]                        ; then
          notify-send --app-name="''${0##*/}" '▼ aria2' "$DESTINATION_DIR"
          dwaria --dir "$DESTINATION_DIR" --add "$remoteReference"
        elif [[ "$remoteReference" =~ ^https:\/\/play.google.com\/store\/apps\/details\?id\= ]]; then
          notify-send --app-name="''${0##*/}" '▼ apkeep' "$DESTINATION_DIR"
          kitty                                \
          --app-id="''${remoteReference//*id=/}" \
          --app-id="kitty_floating"            \
          --hold                               \
          --instance-group "$KITTY_GROUP"      \
          --single-instance                    \
          apkeep "$DESTINATION_DIR"
        else
          notify-send --app-name="''${0##*/}" '▼ yt-dlp' "$DESTINATION_DIR"
          kitty                                  \
          --app-id="''${remoteReference//*id=/}" \
          --app-id="kitty_floating"              \
          --hold                                 \
          --instance-group "$KITTY_GROUP"        \
          --single-instance                      \
          yt_dl_presets "$DESTINATION_DIR" "$remoteReference"
        fi
      done
    '';
  };
};}
