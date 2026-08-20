{ flake.homeModules.dw_yt_dlp = { pkgs, ...} : {
  # TODO create a nixos module dedicated to yt-dlp? And move opensnitch rules from mpv module?

  home.packages = [ pkgs.deno ]; # required by youtube
  programs.yt-dlp.enable =  true;
  programs.yt-dlp.settings = {
    sponsorblock-remove  = "all";
    parse-metadata       = "'title:%(artist)s - %(title)s'";
    embed-metadata       =  true;
    restrict-filenames   =  true;
    embed-thumbnail      =  true;
    write-subs           =  true;
    console-title        =  true;
    trim-filenames       =    50;
    };

};}
