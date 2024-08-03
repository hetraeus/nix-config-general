{ flake.nixosModules.media_mpv = { pkgs, lib, ... }: {
  
services.opensnitch.rules.sub_sub = {
  name        = "sub_sub";
    enabled   = true;
    created     = "2011-11-11T11:11:11.000000000+02:00"; # silence logs
    action    = "allow";
    duration  = "always";
    operator  = {
      type    = "list";
      operand = "list";
      list    = [{
      type    = "simple";
      operand = "dest.port";
      data    = "443";
      } {
      type    = "regexp";
      operand = "dest.host";
      data    = "^(www\.omdbapi\.com|api\.subt\.is|api\.opensubtitles\.(org|com))$";
      }];
    };
};};

flake.homeModules.media_mpv = { pkgs, lib, config, self, ... }: {

home.packages = [
  self.packages.${pkgs.stdenv.hostPlatform.system}.terminal-mpv
  self.packages.${pkgs.stdenv.hostPlatform.system}.fmenu-movie-choose
  (self.legacyPackages.${pkgs.stdenv.hostPlatform.system}.mpvWith {
    subs_langs_dw       = [ "en" "it" ];
    subs_player_langs   = [ "en" "it" "eng" "ita" "italian" "italiano" "english" ];
    audio_player_langs  = [ "en" "it" "eng" "ita" "italian" "italiano" "english" ];
    mpvStyle.background = "#000000";
    mpvStyle.osd-back-color   = config.lib.stylix.colors.withHashtag.base01;
    mpvStyle.osd-border-color = config.lib.stylix.colors.withHashtag.base01;
    mpvStyle.osd-color        = config.lib.stylix.colors.withHashtag.base0D;
    mpvStyle.osd-shadow-color = config.lib.stylix.colors.withHashtag.base00;
    mpvStyle.osd-font         = config.stylix.fonts.sansSerif.name;
    mpvStyle.sub-font         = config.stylix.fonts.sansSerif.name;
    })
  ];

systemd.user.packages = [
  self.packages.${pkgs.stdenv.hostPlatform.system}.fmenu-movie-choose
  ];

xdg.mimeApps.defaultApplications = let
  default_viewer = "terminal-mpv.desktop";
  viewerMimeTypes = [
    "application/mxf"
    "application/ogg"
    "application/sdp"
    "application/smil"
    "application/streamingmedia"
    "application/vnd.apple.mpegurl"
    "application/vnd.ms-asf"
    "application/vnd.rn-realmedia"
    "application/vnd.rn-realmedia-vbr"
    "application/x-cue"
    "application/x-extension-m4a"
    "application/x-extension-mp4"
    "application/x-matroska"
    "application/x-mpegurl"
    "application/x-ogg"
    "application/x-ogm"
    "application/x-ogm-audio"
    "application/x-ogm-video"
    "application/x-shorten"
    "application/x-smil"
    "application/x-streamingmedia"
    "audio/3gpp"
    "audio/3gpp2"
    "audio/AMR"
    "audio/aac"
    "audio/ac3"
    "audio/aiff"
    "audio/amr-wb"
    "audio/dv"
    "audio/eac3"
    "audio/flac"
    "audio/m3u"
    "audio/m4a"
    "audio/mp1"
    "audio/mp2"
    "audio/mp3"
    "audio/mp4"
    "audio/mpeg"
    "audio/mpeg2"
    "audio/mpeg3"
    "audio/mpegurl"
    "audio/mpg"
    "audio/musepack"
    "audio/ogg"
    "audio/opus"
    "audio/rn-mpeg"
    "audio/scpls"
    "audio/vnd.dolby.heaac.1"
    "audio/vnd.dolby.heaac.2"
    "audio/vnd.dts"
    "audio/vnd.dts.hd"
    "audio/vnd.rn-realaudio"
    "audio/vnd.wave"
    "audio/vorbis"
    "audio/wav"
    "audio/webm"
    "audio/x-aac"
    "audio/x-adpcm"
    "audio/x-aiff"
    "audio/x-ape"
    "audio/x-m4a"
    "audio/x-matroska"
    "audio/x-mod"
    "audio/x-mp1"
    "audio/x-mp2"
    "audio/x-mp3"
    "audio/x-mpegurl"
    "audio/x-mpg"
    "audio/x-ms-asf"
    "audio/x-ms-wma"
    "audio/x-musepack"
    "audio/x-pls"
    "audio/x-pn-au"
    "audio/x-pn-realaudio"
    "audio/x-pn-wav"
    "audio/x-pn-windows-pcm"
    "audio/x-realaudio"
    "audio/x-s3m"
    "audio/x-sap"
    "audio/x-scpls"
    "audio/x-shorten"
    "audio/x-tta"
    "audio/x-vorbis+ogg"
    "audio/x-vorbis"
    "audio/x-wavpack"
    "audio/x-wav"
    "video/3gpp2"
    "video/3gpp"
    "video/3gp"
    "video/avi"
    "video/divx"
    "video/dv"
    "video/fli"
    "video/flv"
    "video/mkv"
    "video/mp2t"
    "video/mp4"
    "video/mp4v-es"
    "video/mpeg"
    "video/msvideo"
    "video/ogg"
    "video/quicktime"
    "video/vnd.avi"
    "video/vnd.divx"
    "video/vnd.mpegurl"
    "video/vnd.rn-realvideo"
    "video/webm"
    "video/x-avi"
    "video/x-flc"
    "video/x-flic"
    "video/x-flv"
    "video/x-m4v"
    "video/x-matroska"
    "video/x-mpeg2"
    "video/x-mpeg3"
    "video/x-ms-afs"
    "video/x-ms-asf"
    "video/x-ms-wmv"
    "video/x-ms-wmx"
    "video/x-ms-wvxvideo"
    "video/x-msvideo"
    "video/x-ogm"
    "video/x-ogm+ogg"
    "video/x-theora"
    "video/x-theora+ogg"
    ];
  in lib.genAttrs viewerMimeTypes (_: [ default_viewer ]);

};}
