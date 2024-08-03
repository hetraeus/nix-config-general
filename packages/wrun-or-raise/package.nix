{ perSystem = { pkgs, self', ... }: {
  packages.wrun-or-raise = pkgs.writeShellApplication {
    name          = "wrun-or-raise";
    runtimeInputs = [ pkgs.procps pkgs.coreutils self'.packages.wdotool ];
    text = ''
      [ "$#" -eq 0 ] && exit

      WINDOW="$(wdotool search --class "$1" 2>/dev/null \
              | head --lines=1 \
              | cut --fields=1 \
            || true)"

      # pcmanfm-qt bug
      [[ -z "$WINDOW" ]] && \
      WINDOW="$(wdotool search --pid "$(pgrep --full ".*/$1")" 2>/dev/null \
              | head --lines=1 \
              | cut --fields=1 \
            || true)"

      [[ -z "$WINDOW" ]] && {
        shift
        [ "$#" -ge 1 ] && "$@" & disown
        exit
        }

      [[ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]] && {
        hyprctl dispatch "hl.dsp.focus({ window = 'class:""$1""' })"
        exit
        }
      wdotool windowactivate "$WINDOW" 2>/dev/null
    '';
  };
};}
