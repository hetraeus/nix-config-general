{ perSystem = { pkgs, lib, self', ... }: let
  script = pkgs.writeShellApplication {
    name          = "fmenu-emoticon";
    runtimeInputs = [ pkgs.coreutils pkgs.rofi pkgs.wl-clipboard-rs pkgs.gnugrep pkgs.moreutils ];
    text = let emojiList = ./emojis_list; in ''

      if [[ -f "$HOME/.config/rofi/themes/accent_colors_list.rasi" ]]; then
        THEME_STR='@import "~/.config/rofi/themes/accent_colors_list.rasi"'
      else
        THEME_STR='* { textcol: #cdd3de; bg: #2c393fe2; button: #89ddff; fg: #82aaff; }'
      fi

      EMOJI_LIST=${emojiList}
      EMOJI_HISTORY="$XDG_CACHE_HOME"/emoji_history
      selectedSmileyEntry="$({
        date --iso-8601=date
        date --iso-8601=minutes
        printf '%(%H:%M)T\n'
        [ -f "$XDG_RUNTIME_DIR"/mail ] && { cat "$XDG_RUNTIME_DIR"/mail ; printf '\n'; }
        tac "$EMOJI_HISTORY" || touch "$EMOJI_HISTORY"
        cat "$EMOJI_LIST"
      } | rofi \
          -dmenu                    \
          -scroll-method 1          \
          -theme "${self'.packages.board_list_rasi}" \
          -theme-str "$THEME_STR"   \
          -ballot-unselected-str "" \
          -ballot-selected-str '➤ ' \
          -mesg "snippets"          \
          -no-custom                \
          -transient-window         \
          -p "$(printf ' 🜚  %(%H:%M)T  ')" || true
      )"
      [ -z "$selectedSmileyEntry" ] && exit
      selectedSmiley="''${selectedSmileyEntry%% *}"
      printf '%s' "$selectedSmiley" | wl-copy --regular
      printf '%s' "$selectedSmiley" | wl-copy --primary
      grep --quiet --fixed-strings -- "$selectedSmiley" "$EMOJI_HISTORY" && exit
      { tail --lines=5 "$EMOJI_HISTORY"; grep --fixed-strings -- "^$selectedSmiley " "$EMOJI_LIST"; } \
        | sponge "$EMOJI_HISTORY"
    '';
  };
in {
  packages.fmenu-emoticon = pkgs.symlinkJoin {
    name = "fmenu-emoticon";
    paths = [ script ];
    postBuild = ''
      mkdir -p $out/share/systemd/user
      cat > $out/share/systemd/user/fmenu-emoticon.service <<EOF
[Service]
ExecStart=${lib.getExe script}
Type=exec
PrivateTmp=yes

[Unit]
After=graphical-session.target
Description=fmenu-emoticon
PartOf=graphical-session.target
EOF
    '';
  };
}; }
