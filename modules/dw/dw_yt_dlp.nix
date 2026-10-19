{ flake.homeModules.dw_yt_dlp = { pkgs, lib, ...} : {
  # TODO create a nixos module dedicated to yt-dlp? And move opensnitch rules from mpv module?

  programs.yt-dlp.enable =  true;
  programs.yt-dlp.settings = {
    # required by youtube. 2026-10-12 : deno may close soon
    js-runtimes          = "${lib.getExe pkgs.bun}";
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
