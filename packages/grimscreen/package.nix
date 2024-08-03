{ perSystem = { pkgs, ... }: {
  packages.grimscreen = pkgs.writeShellApplication {
    name               = "grimscreen";
    excludeShellChecks = [ "SC1091" ];
    runtimeInputs = [
      pkgs.blobdrop pkgs.coreutils pkgs.grim pkgs.libnotify pkgs.satty
      pkgs.slurp pkgs.wl-clipboard-rs pkgs.xdg-utils pkgs.nerd-fonts.iosevka
    ];
    text = ''
      source    "$XDG_CONFIG_HOME/user-dirs.dirs"
      SAVE_PATH="$XDG_SCREENSHOTS_DIR"
      mkdir --parents "$SAVE_PATH"
      NOW_PATH="$SAVE_PATH/shot-$( printf '%(%Y%m%d-%H%M%S)T' ).png"
      grim -t ppm -       \
      | satty             \
      --filename  -       \
      --fullscreen        \
      --initial-tool crop \
      --font-family="Iosevka NFM" \
      --output-filename "$NOW_PATH"
      [ ! -f "$NOW_PATH" ] && exit
      while ! "''${finished:-false}"; do
        wl-copy --trim-newline <<< "$NOW_PATH"
        wl-copy --type image/png < "$NOW_PATH"
        action="$(timeout 10 notify-send  \
                --action="open_path=open" \
                --action="drop_file=drop" \
                --action="edit_imag=edit" \
                --expire-time=12000       \
                --app-name="''${0##*/}"   \
                "Capture" "$NOW_PATH"    )"
        case "$action" in
          "open_path") finished=true; xdg-open          "$NOW_PATH"    ;;
          "drop_file") finished=true; coproc { blobdrop "$NOW_PATH" ;} ;;
          "edit_imag") satty        --filename          "$NOW_PATH"     \
                             --output-filename          "$NOW_PATH"     \
                            --font-family="Iosevka NFM" --fullscreen   ;;
                    *) exit                                            ;;
        esac
      done
    '';
  };
};}
