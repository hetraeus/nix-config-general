{ perSystem = { pkgs, ... }: {
  packages.visual-caffeine-get = pkgs.writeShellApplication {
    name          = "visual-caffeine-get";
    runtimeInputs = [ pkgs.gnugrep pkgs.systemd ];
    text = ''
      systemd-inhibit --list --no-pager --no-legend --what=idle \
      | grep --quiet "caffeine notification panel" && {
      # DO NOT EDIT THIS SCRIPT BELOW THIS LINE!!! swaync gets confused and toggles at random
        echo true
        exit
        }
      echo false
    '';
  };
};}
