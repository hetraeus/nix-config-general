{ flake.homeModules.desktop_voices = { pkgs, self, ... } : {
  home.packages = [
    pkgs.piper-tts
    self.packages.${pkgs.stdenv.hostPlatform.system}.voice-en-ryan
    # self.packages.${pkgs.stdenv.hostPlatform.system}.voice-it-serena
    ];
};}
