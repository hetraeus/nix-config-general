{ perSystem = { pkgs, ... }: {
  packages.visual-caffeine = pkgs.writeShellApplication {
    name          = "visual-caffeine";
    runtimeInputs = [ pkgs.gnugrep pkgs.libnotify pkgs.systemd pkgs.procps ];
    text = ''
      PROC_NAME="caffeine notification panel"
      pkill --full "$PROC_NAME" && { notify-send --app-name=caffeine "🥱 Sleeper"; exit; }
      # switch to no sleep mode
      coproc systemd-inhibit --what=idle --why="$PROC_NAME" --who='user' sleep infinity
      notify-send --app-name=caffeine "☕ No sleep"
    '';
  };
};}
