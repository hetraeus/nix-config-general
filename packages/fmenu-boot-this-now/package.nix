{ perSystem = { pkgs, ... }: {
  packages.fmenu-boot-this-now = pkgs.writeShellApplication {
    name          = "fmenu-boot-this-now";
    runtimeInputs = [ pkgs.systemd pkgs.fzf pkgs.gawk pkgs.coreutils pkgs.bat ];
    text = ''
      [ "$EUID" -eq 0 ] || exec run0 "$0" "$@"
      BOOT_STATS="$(bootctl status --no-pager)"
      TARGET="$(
        bootctl list                                               \
        | awk 'BEGIN { FS = ": " }; /^ *id: / {print $2}'        \
        | sort --reverse                                           \
        | fzf  --scroll-off=5                                      \
               --color='fg:#bbbbbb,fg+:#ff5999'                    \
               --info=hidden                                       \
               --header-first                                      \
               --layout=reverse                                    \
               --no-separator                                      \
               --prompt="  "                                       \
               --bind=shift-down:preview-down,shift-up:preview-up  \
               --preview-label=" scroll pressing shift "           \
               --preview-window=bottom,75%,border-top,wrap         \
               --preview "bat --color=always --pager=never --language=nim --style plain <<< \"$BOOT_STATS\"" \
               --header="$0
      $(bootctl list | awk '/\(default\)/{getline; print $2}')"
      )"
      # no choice? Then exit
      [ -z "$TARGET" ] && exit
      bootctl set-oneshot "$TARGET"
      systemctl reboot
    '';
  };
};}
