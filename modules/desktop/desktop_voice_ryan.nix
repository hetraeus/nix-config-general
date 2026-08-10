{ flake.homeModules.desktop_voice_ryan = { pkgs, self, ... } : {
  home.packages = [ pkgs.piper-tts self.packages.${pkgs.stdenv.hostPlatform.system}.voice-en-ryan ];
};}
