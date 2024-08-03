{ perSystem = { pkgs, ... }: {
  packages.fdx = pkgs.writeShellApplication {
    name          = "fdx";
    runtimeInputs = [ pkgs.coreutils pkgs.xdg-utils pkgs.fd ];
    text = ''
      (( $# == 0 )) && exit
      xdg-open "$(fd --type  f     \
               --extension 3gp     \
               --extension avi     \
               --extension flac    \
               --extension flv     \
               --extension mkv     \
               --extension mov     \
               --extension mp2     \
               --extension mp3     \
               --extension mp4     \
               --extension oga     \
               --extension ogg     \
               --extension ogv     \
               --extension webm    \
               --extension wma     \
               --extension wmv     \
               --extension wav     \
                                   \
               --extension jpeg    \
               --extension jpg     \
               --extension png     \
               --extension tiff    \
               --extension gif     \
                                   \
               --extension cbz     \
               --extension epub    \
               --extension pdf     \
                                   \
               --max-results=1     \
               -- "''${@// /*}" .  \
               | tee  /dev/tty  -- \
               )"
    '';
  };
};}
