{ perSystem = { pkgs, lib, self', ... }: {
  packages.hyprmenu-launch = let
    hyprmenu-script = pkgs.writeShellApplication {
      name          = "hyprmenu-script";
      text          = builtins.readFile ./hyprmenu;
      runtimeInputs = [
        pkgs.mpc
        pkgs.wl-clipboard-rs
        pkgs.playerctl
        pkgs.wireplumber
        pkgs.piper-tts
        pkgs.wlr-randr
        pkgs.systemd
        self'.packages.qr-selectread
        self'.packages.qr-code-from-clipboard
        self'.packages.visual-brightness
      ];
    };
    rofiTheme = builtins.path {
      path = ./cli.rasi;
      name = "cli.rasi";
    };


  in pkgs.writeShellApplication {
    name          = "hyprmenu-launch";
    runtimeInputs = [ hyprmenu-script pkgs.rofi ];
    text = ''
      if [[ -f "$HOME/.config/rofi/themes/accent_colors_list.rasi" ]]; then
        THEME_STR='@import "~/.config/rofi/themes/accent_colors_list.rasi"'
      else
        THEME_STR='* { textcol: #cdd3de; bg: #2c393fe2; button: #89ddff; fg: #82aaff; }'
      fi
      
      rofi                 \
      -p ""                \
      -monitor             \
      -show   hyprmenu     \
      -scroll-method 1     \
      -selected-row  4     \
      -modes "hyprmenu:${lib.getExe hyprmenu-script}" \
      -theme-str "$THEME_STR"  \
      -theme ${rofiTheme}
    '';
  };
};}
