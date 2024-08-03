{ perSystem = { pkgs, self', ... }: {
  packages.fmenu-powerprofiles = let

    script = pkgs.writeShellApplication {
      name          = "fmenu-powerprofiles";
      runtimeInputs = [ pkgs.rofi pkgs.tuned pkgs.coreutils ];
      text = ''
        if [[ -f "$HOME/.config/rofi/themes/accent_colors_list.rasi" ]]; then
          THEME_STR='@import "~/.config/rofi/themes/accent_colors_list.rasi"'
        else
          THEME_STR='* { textcol: #cdd3de; bg: #2c393fe2; button: #89ddff; fg: #82aaff; }'
        fi

        CHOICE="$(tuned-adm list profiles   \
        | head --lines=-1                   \
        | tail --lines=+2                   \
        | rofi   -dmenu                     \
        -scroll-method 1                    \
        -theme "${self'.packages.board_list_rasi}" \
        -theme-str "$THEME_STR"             \
        -ballot-unselected-str ""           \
        -ballot-selected-str '➤ '           \
        -no-custom                          \
        -mesg  "$(tuned-adm active)
        recommended profile : $(tuned-adm recommend)" \
        -p "$(printf ' 🜚  %(%H:%M)T  ')"
        )"
         # TODO what board_list??
        [[ -n "$CHOICE" ]] && tuned-adm profile "$(cut --fields=2 --delimiter=' ' <<< "$CHOICE")"
      '';
    };

  desktopItem = pkgs.makeDesktopItem {
    name         = "tuned-power-profiles";
    genericName  = "Power profiles tuned performance battery saving";
    desktopName  = "Power profiles tuned performance battery saving";
    icon         = "power-profile-balanced-symbolic";
    terminal     = false;
    categories   = [ "Utility" ];
    exec         = "fmenu-powerprofiles";
    };

  in pkgs.buildEnv {
    name             = "fmenu-powerprofiles-wrapper";
    paths            = [ script desktopItem ];
    meta.mainProgram = "fmenu-powerprofiles";
  };

};}
