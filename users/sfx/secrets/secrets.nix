{ flake.homeModules.secrets = { ... }: {
  
  sops.secrets."ai-api-mistral" = { sopsFile = ./ai-api.yaml ; };
  sops.secrets."ai-api-antigravity"  = { sopsFile = ./ai-api.yaml ; };
  sops.secrets.mpd_permissions.sopsFile = ./mpd_permissions.yaml;
  sops.secrets.mpd_soundcloud.sopsFile  = ./mpd_soundcloud.yaml;

  sops.secrets.aria2_torrent = {
    path     = "%r/aria2/torrent.conf"; # Needed by the dw_ launchers
    sopsFile =   ./aria2_torrent.yaml ;
    };

  sops.secrets.sbuku_search_engines = {
    sopsFile = ./sbuku_search_engines.yaml ;
    path     =     "%r/search_engines.json";
    };
    
  sops.secrets.mail = {
    sopsFile = ./mail.yaml ;
    path     = "%r/mail";
    };

  sops.secrets.watch_cams001 = {
    sopsFile = ./cams_001.yaml ;
    # mode     = "0400";
    # owner    = osConfig.users_list.principalUser;
    # group    = "users";
    };
};}
