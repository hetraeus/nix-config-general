{ perSystem = { pkgs, ... }: {
  packages.yt-dl-presets = pkgs.writeShellApplication {
    name          = "yt-dl-presets";
    runtimeInputs = [ pkgs.yt-dlp ];
    excludeShellChecks = [ "SC1091" ];
    text = ''
      source    "$XDG_CONFIG_HOME/user-dirs.dirs"
      DESTINATION_DIR="''${1:-ELSE}"
      shift
      [[ ! -d "$DESTINATION_DIR" ]]  &&  { mkdir "''${XDG_MUSIC_DIR:-~}/.temp" ; }
      echo -e "\e]2;🔽 dwnld $DESTINATION_DIR\a"
      case "$DESTINATION_DIR" in
        "''${XDG_MUSIC_DIR:-~}/.temp" ) yt-dlp \
        --sponsorblock-remove all              \
        --parse-metadata  'title:%(artist)s - %(title)s' \
        --embed-metadata                       \
        --restrict-filenames                   \
        --console-title                        \
        --trim-filenames  70                   \
        --output          "''${XDG_MUSIC_DIR:-~}/.temp/%(artist)s/%(album)s/%(track_number)s_%(title)s_%(%section_number)s_%(section_title)s.%(ext)s" \
        --output          chapter:"''${XDG_MUSIC_DIR:-~}/.temp/%(artist)s/%(album)s/%(track_number)s_%(title)s_%(%section_number)s_%(section_title)s.%(ext)s" \
        --embed-thumbnail                      \
        --extract-audio                        \
        --format          bestaudio            \
        --audio-format    mp3                  \
        --split-chapters                       \
        --convert-subs    srt                  \
        -- "$@"
        echo -e "\e]2;🍏 dwnld $DESTINATION_DIR\a"
        exit
        ;;
        MUSIC_CAR ) yt-dlp          \
        --sponsorblock-remove all   \
        --parse-metadata    'title:%(artist)s - %(title)s' \
        --embed-metadata            \
        --restrict-filenames        \
        --console-title             \
        --trim-filenames  70        \
        --paths           temp:"''${XDG_RUNTIME_DIR:-~}"        \
        --paths           "/run/media/$USER/BLISS_ONLIN/Multi/" \
        --output          '%(title)s.%(ext)s' \
        --extract-audio             \
        --format          bestaudio \
        --audio-format    mp3       \
        --no-playlist               \
        --split-chapters            \
        -- "$@"
        echo -e "\e]2;🍏 dwnld $DESTINATION_DIR\a"
        exit
        ;;
        BOOK_CAR  ) yt-dlp          \
        --sponsorblock-remove all   \
        --parse-metadata  'title:%(artist)s - %(title)s' \
        --embed-metadata            \
        --restrict-filenames        \
        --console-title             \
        --trim-filenames  70        \
        --output          '%(title)s.%(ext)s' \
        --extract-audio             \
        --format          bestaudio \
        --audio-format    mp3       \
        --paths           temp:"''${XDG_RUNTIME_DIR:-/tmp/}"     \
        --paths           "/run/media/$USER/BLISS_ONLIN/Books/"  \
        --convert-subs    srt       \
        -- "$@"
        echo -e "\e]2;🍏 dwnld $DESTINATION_DIR\a"
        exit
        ;;
        "''${XDG_MUSIC_DIR:-~}/Musical videos"  ) yt-dlp   \
        --sponsorblock-remove all                          \
        --parse-metadata    'title:%(artist)s - %(title)s' \
        --embed-metadata                                   \
        --restrict-filenames                               \
        --console-title                                    \
        --trim-filenames    70                             \
        --output     "''${XDG_MUSIC_DIR:-~}/Musical videos/%(title)s.%(ext)s" \
        --sub-langs        all                             \
        --write-subs                                       \
        --convert-subs     srt                             \
        --split-chapters                                   \
        -- "$@"
        echo -e "\e]2;🍏 dwnld $DESTINATION_DIR\a"
        exit
        ;;
        "''${XDG_VIDEOS_DIR:-~}"* ) yt-dlp \
        --sponsorblock-remove all          \
        --parse-metadata    'title:%(artist)s - %(title)s' \
        --embed-metadata                   \
        --restrict-filenames               \
        --console-title                    \
        --trim-filenames    70             \
        --output     "''${DESTINATION_DIR:-~}/%(title)s.%(ext)s" \
        --embed-thumbnail                  \
        --sub-langs        all             \
        --write-subs                       \
        --convert-subs     srt             \
        -- "$@"
        echo -e "\e]2;🍏 dwnld $DESTINATION_DIR\a"
        exit
        ;;
        * ) yt-dlp                \
        --sponsorblock-remove all \
        --parse-metadata    'title:%(artist)s - %(title)s' \
        --embed-metadata          \
        --restrict-filenames      \
        --console-title           \
        --trim-filenames      70  \
        --sub-langs           all \
        --write-subs              \
        -- "$@"
        cd "$DESTINATION_DIR" || exit
        echo -e "\e]2;🍏 dwnld $DESTINATION_DIR\a"
        exit
        ;;
      esac
    '';
  };
};}
