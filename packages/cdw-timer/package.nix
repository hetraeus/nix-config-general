{ perSystem = { pkgs, ... }: {
  packages.cdw-timer = pkgs.writeShellApplication {
    name          = "cdw-timer";
    runtimeInputs = [
      pkgs.brightnessctl
      pkgs.coreutils
      pkgs.libnotify
      pkgs.systemd
      pkgs.sox
    ];
    text = ''
      [[ "$#" -le 1 ]] && { echo "usage: $0 memo time"; exit; }
      WHAT=$1
      shift
      systemd-run                      \
      --description="$WHAT"            \
      --timer-property=AccuracySec=10s \
      --on-calendar="$(date --date="$*" '+%Y-%m-%d %H:%M:%S')" \
      --user sh -c                     \
      "notify-send --urgency=critical '⏰ COUNTDOWN' \"$WHAT\"
      nohup play --no-show-progress -r 1200 -n synth .25 triangle 400-100 repeat 12 &>/dev/null &
      for i in {1,0,1,0,1,0,1,0}; do brightnessctl --device='input*::capslock' s \$i; sleep .2; done
      "
      systemctl --no-pager --user list-timers --all
    '';
  };
};}
