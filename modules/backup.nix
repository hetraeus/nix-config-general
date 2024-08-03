{ flake.nixosModules.backup  = { pkgs, ... }: {
  environment.systemPackages = [ pkgs.rclone pkgs.kopia pkgs.rsync ];
  environment.shellAliases.rsync = "rsync --progress ";
  };

flake.homeModules.backup = { config, pkgs, lib, ... } : {
  services.restic.enable = true;
  home.packages = [ pkgs.rsync ];
  home.shellAliases.rsync = "rsync --progress";
  programs.rclone.enable  = true;
  xdg.dataFile."rclone_config_pw.yaml".source = ../users/${config.home.username}/secrets/rclone_config.yaml ;
  home.sessionVariables.RCLONE_PASSWORD_COMMAND="${lib.getExe pkgs.sops} --config=${config.xdg.dataHome}/../secrets/rclone_sops.yaml decrypt ${config.xdg.dataHome}/rclone_config_pw.yaml --output-type binary";
  home.sessionVariables.RCLONE_CONFIG="${config.xdg.dataHome}/../secrets/rclone.conf";

};}
