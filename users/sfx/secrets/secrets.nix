{ flake.homeModules.secrets = { config, ... }: {

  home.file.".gnupg" = { source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.dataHome}/../config/.gnupg"; };

  home.sessionVariables.SOPS_AGE_KEY_FILE = "${config.xdg.dataHome}/../secrets/sops-age/sops-age.txt";
  sops.age.keyFile = config.home.sessionVariables.SOPS_AGE_KEY_FILE;
  # sops.secrets."ai-api-mistral"     = { sopsFile = ./ai-api.yaml ; };
  # sops.secrets."ai-api-antigravity" = { sopsFile = ./ai-api.yaml ; };

  sops.secrets.aria2_torrent = {
    path     = "%r/aria2/torrent.conf"; # Needed by the dw_ launchers
    sopsFile =   ./aria2_torrent.yaml ;
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
