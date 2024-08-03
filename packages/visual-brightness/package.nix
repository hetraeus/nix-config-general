{ perSystem = { pkgs, ... }: {
  packages.visual-brightness = pkgs.writeShellApplication {
    name          = "visual-brightness";
    runtimeInputs = [ pkgs.systemd pkgs.brightnessctl pkgs.wl-gammarelay-rs pkgs.gnugrep ];
    text = ''
      case "$1" in
        "up"   )
          busctl --user -- get-property rs.wl-gammarelay / rs.wl.gammarelay Brightness \
          | grep --quiet 'd 1' && {
            brightnessctl --quiet --class="backlight" s 1%+
            exit; }
          busctl --user -- call rs.wl-gammarelay / rs.wl.gammarelay UpdateBrightness d +.1
          ;;
        "down" )
          brightnessctl --class="backlight" --machine-readable \
          | grep --quiet ',1%,' && {
            busctl --user -- get-property rs.wl-gammarelay / rs.wl.gammarelay Brightness \
            | grep --quiet 'd 0.1' && exit
            busctl --user -- call rs.wl-gammarelay / rs.wl.gammarelay UpdateBrightness d -.1
            exit; }
          brightnessctl --quiet --class="backlight" s 1%-
          ;;
      esac
    '';
  };
};}
