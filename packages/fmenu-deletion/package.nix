{ perSystem = { pkgs, ... }: {
  packages.fmenu-deletion = pkgs.writeShellApplication {
    name          = "fmenu-deletion";
    runtimeInputs = [
      pkgs.sox pkgs.fzf pkgs.libnotify pkgs.coreutils pkgs.dust
      pkgs.gnugrep pkgs.glib pkgs.rmlint pkgs.kitty pkgs.edir
    ];
    text = ''
      #set -euxo pipefail # THIS DISABLE DELETION !
      play --no-show-progress -n synth .3 triangle 900-110 vol 0.08 &
      IFS=$'\n'
      NONE="🟩 none"
      DSIZE="◕  disk size "
      DEDUP="🥆  deduplicate"
      RENAM="🦜 batch rename"
      EMPTY_DIRS="🌴 prune dirs"
      UNTRASH="🌱 restore from trash "
      PREV="🦕 prev ver"
      notify-app(){ notify-send --app-name="''${0##*/}" "$1" "''${@:2}"; }
      export  FZF_DEFAULT_OPTS="\
      --layout=reverse          \
      --info=inline-right       \
      --scroll-off=5            \
      --color='gutter:-1'       \
      --no-separator            \
      --gutter=' '              \
      --pointer=' '             \
      --prompt='  '             \
      "
      readarray -t DEL_LIST < <(fzf                \
      --multi                                      \
      --exact                                      \
      --header-first                               \
      --bind ctrl-a:select-all                     \
      --color=header:bright-red:bold               \
      --preview='head --lines=5 -- {} 2>/dev/null' \
      --preview-window=down,18%,border-top,wrap    \
      --header=\
      "            ╓───────────🔥🔥🔥────────────╖
                  ║ Select files to be DELETED  ║
                  ║  tab    : select multiple   ║
                  ║  ctrl+a : select ALL        ║
                  ╙─────────────────────────────╜
      $0"  <<< "$NONE
      $DSIZE
      $EMPTY_DIRS
      $DEDUP
      $RENAM
      $PREV
      $UNTRASH
      $*" )
      # case: no file selected
      (( ''${#DEL_LIST[@]} == 0 )) ||
      grep --line-regexp "$NONE" <<< "''${DEL_LIST[@]}" && notify-app '🍀 no file selected!' && exit
      if ((  ''${#DEL_LIST[@]}  == 1 )); then
        case "''${DEL_LIST[0]}" in
        # case prune empty dirs
        "$EMPTY_DIRS")
          if   find "$@"   -type d -empty -delete; then
               notify-app '🌴 pruned empty dirs!' ""
          else notify-app '🎋 pruning errors !' ""; fi
          exit ;;
        # case trash undelete
        "$UNTRASH"   )
          gio trash --restore "$(gio trash --list | fzf --with-nth=2 --delimiter="\t" --bind="enter:become(echo {1})" )"
          sleep .5
          exit;;
        # case prev version from snapshots
        "$PREV"      ) for each_file in "$@"; do kitty --app-id="kitty_floating" fmenu-prev "$each_file"; done
          exit ;;
        # case disk usage
        "$DSIZE"     ) dust --reverse "$@"; read  -rn1; exit ;;
        # case batch rename
        "$RENAM"     ) edir; exit ;;
        # case deduplicate assuming btrfs
        "$DEDUP"     )
          rmlint --types="duplicates" --config=sh:handler=clone --progress --loud -- "$*"
          read    -rn1; exit ;;
        esac
        # case single file
        READY_DEL_LIST=("''${DEL_LIST[0]}")
      fi
      (( ''${#READY_DEL_LIST[@]} >= 2 )) || {
          READY_DEL_LIST=("''${DEL_LIST[@]/$NONE}")
          for each_op in "$DSIZE" "$DEDUP" "$RENAM" "$EMPTY_DIRS" "$UNTRASH" "$PREV"; do
            READY_DEL_LIST=("''${READY_DEL_LIST[@]/$each_op}")
            done }
      DELETION_GO="🔥 DELETE 🔥"
      CONFIRMED="$(fzf             \
        --border-label=" 🔥 PROCEED WITH DELETION ? 🔥 " \
        --color='fg:#bbbbbb,preview-label:#435373,preview-fg:#666666' \
        --preview="printf --  '%s\n' \"''${READY_DEL_LIST[*]}\" | grep --invert-match '^ *$'" \
        --preview-window=bottom,77%,border-top   \
        --preview-label=" scroll pressing ctrl " \
        --margin=20%,20%,20%,20%   \
        --header-first             \
        --disabled                 \
        --no-info                  \
        --border                   \
        <<< "🍀 NO
      🚮 Trash
      $DELETION_GO")"
      [[ $CONFIRMED == *"Trash" ]] && {
        gio trash -- "''${READY_DEL_LIST[@]}"
        notify-app '🚮 TRASH' -- "$*"
        exit
      }
      [[ $CONFIRMED != "$DELETION_GO" ]] && {
        notify-app '🍀 no deletions !'   " "
        exit
      }
      rm --recursive --force -- "''${READY_DEL_LIST[@]}" && {
        notify-app '🔥 DELETED FILES' -- "$*"
        exit
        }
      notify-app   '⚠️ deletion errors !' -- "''${READY_DEL_LIST[@]}"
    '';
  };
};}
