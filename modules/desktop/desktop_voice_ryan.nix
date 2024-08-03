{ flake.homeModules.desktop_voice_ryan = { pkgs, self, ... } : {
  home.packages = [ pkgs.piper-tts self.packages.${pkgs.stdenv.hostPlatform.system}.voice-en-ryan ];

  # INFO: coqui xtts
  # let pkgs_pinned_1 = import (builtins.fetchTarball {
  #   url = "https://github.com/NixOS/nixpkgs/archive/e6f23dc08d3624daab7094b701aa3954923c6bbb.tar.gz";
  #   sha256 = "0m0xmk8sjb5gv2pq7s8w7qxf7qggqsd3rxzv3xrqkhfimy2x7bnx";
  #   }) { system=pkgs.stdenv.hostPlatform.system; };
  # in

};}
