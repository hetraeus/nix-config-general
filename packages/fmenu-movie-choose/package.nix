{ perSystem = { pkgs, self', lib, ... }: {
  packages.fmenu-movie-choose = let
    script = pkgs.writeShellApplication {
      name               = "fmenu-movie-choose";
      excludeShellChecks = [ "SC1091" ];
      runtimeInputs      = [
        pkgs.moreutils pkgs.coreutils pkgs.fd pkgs.gnugrep pkgs.gawk pkgs.rofi
        self'.packages.mpv
         ];
      text = ''
        # MOVIE_FIFO="$1"
        if [[ -f "$HOME/.config/rofi/themes/accent_colors_list.rasi" ]]; then
          THEME_STR='@import "~/.config/rofi/themes/accent_colors_list.rasi"'
        else
          THEME_STR='* { textcol: #cdd3de; bg: #2c393fe2; button: #89ddff; fg: #82aaff; }'
        fi

        source     "$XDG_CONFIG_HOME/user-dirs.dirs"
        MOVIES_DIR="$XDG_VIDEOS_DIR"
        MOVIE_HISTORY="$XDG_CACHE_HOME"/movie_history
        MOVIE_CHOICE="$({
          tac              "$MOVIE_HISTORY"
          echo              '📷 webcams.sh' # './' and '.sh' are here just to pass fzf filter
          fd --base-directory "$MOVIES_DIR" \
             --follow                       \
             --type      f                  \
             --extension mp4                \
             --extension flv                \
             --extension webm               \
             --extension avi                \
             --extension mkv                \
             --extension m4v                \
        ;} | awk '!x[$0]++'                 \
           | rofi                           \
             -dmenu                         \
             -scroll-method 1               \
             -theme "${self'.packages.board_list_rasi}" \
             -theme-str "$THEME_STR"        \
             -ballot-unselected-str ""      \
             -ballot-selected-str '➤ '      \
             -mesg  "snippets"              \
             -no-custom                     \
             -p "$(printf ' 🜚  %(%H:%M)T  ')"
             )"
        [ -z "$MOVIE_CHOICE" ] && exit
        [ "$MOVIE_CHOICE" == "📷 webcams.sh" ] && {       \
          MOVIE_CHOICE="$(~/.local/bin/scripts/web_cams)" \
          MOVIES_DIR=""                                   \
        ;} || \
        grep   --quiet   "$MOVIE_CHOICE"  "$MOVIE_HISTORY" || {
          tail --lines=4 "$MOVIE_HISTORY"
          echo           "$MOVIE_CHOICE"
          } | sponge     "$MOVIE_HISTORY"
        mpv "$MOVIES_DIR/$MOVIE_CHOICE"
      '';
    };
    # serviceTemplate = ./fmenu-movie-choose.service;
    desktopItem     = pkgs.makeDesktopItem {
      name        = "movie-play";
      genericName = "play movies";
      exec        = "${lib.getExe script}";
      desktopName = "play movies";
      categories  = [ "AudioVideo" "Audio" ];
      icon        = "video";
    };
  in pkgs.buildEnv {
    name  = "fmenu-movie-choose-wrapper";
    paths = [ script desktopItem ];
    meta.mainProgram = "fmenu-movie-choose";
    # postBuild = ''
    #   mkdir --parents $out/share/systemd/user
    #   substitute ${serviceTemplate} $out/share/systemd/user/fmenu-movie-choose.service \
    #     --replace "@BIN@" "${lib.getExe script}"
    # '';
  };
};}
