{ self', brightnessctl, coreutils, gcolor3, gawk, gnused, mpc, piper-tts, pipewire, playerctl, procps, rofi, wl-clipboard-rs, xdg-utils,
  writeShellApplication }: let

  hypr-hide-floats = self'.packages.hypr-hide-floats;
  wdotool = self'.packages.wdotool;
  clicker = writeShellApplication {
    name = "clicker";
    runtimeInputs = [ wdotool ];
    text = ''
      while :; do
      for _ in {1..250}; do wdotool click 1 ; sleep .1 ; done
        [[ "$1" == "oneshot" ]] && break
        # [[ "$(fzf --bind=left-click:accept --no-separator --header="again?" --no-info --reverse <<< "yes\nno")" == "no" ]] && break
        done
  '';};

in writeShellApplication {
  name = "piemenu_1";
  excludeShellChecks = [ "SC1009" "SC1064" "SC1065" "SC1072" "SC1073" ];
  text = ''
    TOGGLE_FLOATS="${hypr-hide-floats}"
    ONNX="${self'.packages.voice-en-ryan}/model.onnx"
    '' + builtins.readFile ./piemenu ;

  runtimeInputs = [
    clicker
    self'.packages.visual-brightness

    brightnessctl
    coreutils
    gcolor3
    gawk
    gnused
    mpc
    piper-tts
    pipewire
    playerctl
    procps
    rofi
    wl-clipboard-rs
    xdg-utils
    wdotool
    ];
}
