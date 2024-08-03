{ perSystem = { pkgs, ... }: {
  packages.fmenu-radio-mpd = let
    script = pkgs.writeShellApplication {
      name          = "fmenu-radio-mpd";
      runtimeInputs = [ pkgs.curl pkgs.jq pkgs.fzf pkgs.mpc pkgs.gnugrep pkgs.mpv pkgs.systemd ];
      text = ''
        export FZF_DEFAULT_OPTS="\
          --layout=reverse       \
          --ansi                 \
          --no-separator         \
          --scroll-off=5         \
          --prompt='  '          \
          --pointer=' '          \
          --gutter=' '
        "
        RADIO_LIST="$XDG_CACHE_HOME"/radio_list.json
        operation="''${*-}"
        [[ "$operation" == "refresh" ]] && {
          curl --silent http://all.api.radio-browser.info/json/stations/search --output "$RADIO_LIST"
          operation=""
          }
        while true; do
          # the space before the ansi 0m is meant to separate the url
          RADIO_PLAYLIST="$(
            jq --raw-output '.[] | select(.lastcheckok == 1) | "\(.name)\t\u001b[0;90m \t\(.tags) \(.url_resolved) \u001b[0m"' "$RADIO_LIST" \
            | fzf                       \
            --multi                     \
            --info=hidden               \
            --query="''${operation}"    \
            --header-first              \
            --accept-nth='{-1}'         \
            --color='gutter:-1,bg+:#80cbc4,hl+:#14a57c,fg+:#253136,hl:#ffcc00' \
            --header="$0
          $RADIO_LIST")"
          [[ "$RADIO_PLAYLIST" == "" &&  "$operation" == "radio_oneshot" ]] && exit
          [[ "$RADIO_PLAYLIST" == ""                                     ]] && continue
          if [[ -n "$(command -v mpv)" ]]; then
            mpv  "$RADIO_PLAYLIST" "$RADIO_PLAYLIST" "$RADIO_PLAYLIST"
          elif systemctl is-active --quiet mpd --user; then
            MPD_HOST="$(systemctl  --user show --property Listen mpd.socket | grep --only-matching "$XDG_RUNTIME_DIR"'/.* ')"
            #MPD_HOST="$(awk 'BEGIN { FS = "[\"@]"}; /^password  *.*@read,add,control,player/{print $2}' $MPD_CONF@localhost"
            #MPD_HOST="$(systemctl --quiet --user list-sockets mpd.socket | awk 'BEGIN{FS="[ :]"} NR==1{print $1}')"
             mpc --host="$MPD_HOST" --quiet insert "$RADIO_PLAYLIST" "$RADIO_PLAYLIST" "$RADIO_PLAYLIST"
             mpc --host="$MPD_HOST" --quiet next
             mpc --host="$MPD_HOST" --quiet play # when list was empty force play
          # elif systemctl is-active  --quiet mpd ; then
          else exit; fi
          done
      '';
    };
    desktopItem = pkgs.makeDesktopItem {
      name        = "webradios";
      genericName = "listen music";
      desktopName = "web radios";
      icon        = "radio";
      terminal    = false;
      categories  = [ "AudioVideo" "Audio" ];
      exec        = "fmenu-radio-mpd";
    };
  in pkgs.buildEnv {
    name  = "fmenu-radio-mpd-wrapper";
    paths = [ script desktopItem ];
    meta.mainProgram = "fmenu-radio-mpd";
  };
};}
