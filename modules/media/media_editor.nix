{ flake.homeModules.media_editor = { pkgs, lib, self, ... } : {

  programs.obs-studio.enable = true;
  home.packages = [
    pkgs.gimp3-with-plugins
    pkgs.gimp3Plugins.gmic
    pkgs.pixieditor
    pkgs.inkscape
    pkgs.satty
    pkgs.krita
    pkgs.krita-plugin-gmic
    pkgs.gmic-qt
    pkgs.drawing
    pkgs.graphite
    self.packages.${pkgs.stdenv.hostPlatform.system}.online-editors

    pkgs.audacity
    pkgs.ffmpeg
    pkgs.handbrake
    ];
};}
