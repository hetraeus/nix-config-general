{ perSystem = { pkgs, ... }: {
  packages.pink-noise = let
    pink-noise-inner = pkgs.writeShellApplication {
      name           = "pink-noise";
      runtimeInputs  = [ pkgs.sox ];
      text = ''
        play -c2 -n synth pinknoise \
          band -n 280 80            \
          band -n 60 25             \
          gain +20                  \
          treble +40 500            \
          bass -3 20                \
          flanger 4 2 95 50 .3      \
          sine 50 lin
      '';
    };
    script = pkgs.writeShellApplication {
      name          = "pink-noise";
      runtimeInputs = [ pkgs.procps pink-noise-inner ];
      text = ''
        pkill --full "synth pinknoise band" || pink-noise
      '';
    };
    desktopItem   = pkgs.makeDesktopItem {
      name        = "pink-noise";
      exec        = "pink-noise";
      desktopName = "drone ambient";
      genericName = "pink noise drone ambient";
      comment     = "background noise";
      categories  = [ "AudioVideo" "Audio" ];
      icon        = "bee-package-manager";
    };
  in pkgs.buildEnv {
    name  = "pink-noise-wrapper";
    meta.mainProgram = "pink-noise";
    paths = [ script desktopItem ];
  };
};}
