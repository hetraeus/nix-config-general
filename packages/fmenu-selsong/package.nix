{ perSystem = { pkgs, ... }: {
  packages.fmenu-selsong = pkgs.writeShellApplication {
    name          = "fmenu-selsong";
    runtimeInputs = [
      pkgs.systemd pkgs.fzf pkgs.mpc pkgs.gnugrep pkgs.gawk pkgs.ffmpeg
      pkgs.picard pkgs.wl-clipboard-rs pkgs.xdg-utils pkgs.rsync pkgs.blobdrop
    ];
    text = ''
      #MPD_HOST="$XDG_RUNTIME_DIR/mpd/socket"
      #systemctl --user show mpd.socket --property=Listen | grep '/run/user/[0-9][0-9]*/[a-z][a-z/]*' --only-matching
      #MPD_HOST="$(systemctl --quiet --user list-sockets mpd.socket | awk 'BEGIN{FS="[ :]"} NR==1{print $1}')"
      MPD_HOST="$(systemctl --user show --property Listen mpd.socket | grep --only-matching "$XDG_RUNTIME_DIR"'/.* ')"
      MPD_CONF="/nix/store/$(systemctl show --user mpd --property='ExecStart' | grep '[a-z0-9]*-mpd.conf' --only-matching)"
      COLLECTION_DIR="$(awk 'BEGIN { FS = "\"" }; /^music_directory/{print $2}' "$MPD_CONF")"
      SONG="$(mpc --host="$MPD_HOST" --format=%file% current)"
      music_source="''${COLLECTION_DIR/\~/$HOME}/$SONG"
      export  FZF_DEFAULT_OPTS="\
        --layout=reverse        \
        --info=hidden           \
        --header-first          \
        --scroll-off=5          \
        --no-separator          \
        --gutter=' '            \
        --prompt='  '           \
        --pointer=' '           \
        --color='gutter:-1'
      "
      media_info(){
        ffprobe -v error -show_format -show_streams "$music_source"
        read -rp "Press enter to continue"
        }
      spectrogram(){
        # sox "$music_source" -n spectrogram -o "$music_source"_spctr.png
        ffmpeg -i "$music_source" -lavfi showspectrumpic=s=1920x1080:mode=separate:fscale=lin:scale=log "''${music_source%\.*}"_spectr.png
        wl-copy <<< "''${music_source%\.*}"_spectr.png
        xdg-open "''${music_source%\.*}"_spectr.png
        }
      soundwave(){
        ffmpeg -i "$music_source" -f lavfi -i color=c=black:s=1920x1080 -filter_complex "showwavespic=s=1920x1080:colors=white[fg];[1:v][fg]overlay=format=auto" -frames:v 1 "''${music_source%\.*}"_sndwv.png
        wl-copy <<< "''${music_source%\.*}"_sndwv.png
        xdg-open "''${music_source%\.*}"_sndwv.png
        }
      mus_copy(){
        wl-copy <<< "$music_source"
        blobdrop    "$music_source"
        }
      mus_storage(){
        blobdrop "''${music_source%/*}"
        }
      mus_copy_car(){
        {  case "$SONG" in
            *.mp3) rsync     "$music_source" "/run/media/$USER/BLISS_ONLIN/Multi/"              ;;
            *    ) SONGNAME="$(mpc --host="$MPD_HOST" --format=%title% current)"
                   ffmpeg -i "$music_source" "/run/media/$USER/BLISS_ONLIN/Multi/$SONGNAME.mp3" ;;
          esac } && echo "🔔 track sent to car" "$SONG" || echo "🚧 CANNOT send to car" "$SONG"
        echo "
      press enter"; read -r
      }
      operation="$(fzf   \
        --no-info        \
        --color='fg:#bbbbbb' \
        --header="$0
      ''${SONG##*/}" <<< \
      "🚗 car  song
      🐑 copy song
      🏷  tag editor
      ℹ  media info
      👻 spectrogram
      ∿  soundwave
      📨 send
      $(mpc --host="$MPD_HOST" listall)")"
      # 📁 storage
      case "''${operation}" in
        "🚗 car  song"   ) mus_copy_car                                                    ;;
        "ℹ  media info"  ) media_info                                                      ;;
        "👻 spectrogram" ) spectrogram                                                     ;;
        "∿ soundwave"    ) soundwave                                                       ;;
        "🐑 copy song"   ) mus_copy                                                        ;;
      #  "📻 radio"       ) fmenu-radio-mpd                               radio_oneshot     ;;
        "🏷  tag editor"  ) picard                                   "''${music_source%/*}" ;;
        "📨 send"        ) ~/.local/bin/scripts/fmenu-send-regular  "''${music_source}"    ;;
        "📁 storage"     ) mus_storage                                                     ;;
                       * ) mpc add "$operation";;
      esac
    '';
  };
};}
