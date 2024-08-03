{ flake.nixosModules.discord = {

  services.opensnitch.rules.pop_discord = {
    name        = "pop_discord";
    created     = "2018-04-07T14:13:27.903996051+02:00"; # silence logs
    enabled     = true;
    action      = "allow";
    duration    = "always";
    operator    = {
      type      = "list";
      operand   = "list";
      sensitive = false;
      list      = [{
       type     = "regexp";
       operand  = "process.command";
       data     = "/nix/store/.*-electron-unwrapped-.*/libexec/electron/electron";
       } {
       type     = "regexp";
       operand  = "dest.host";
       data     = "^((.*|)discord(.*|app)\.(gg|net|com)|badges\.vencord\.dev|.*\.google(apis|video)\.com|i\.ytimg\.com|yt3\.ggpht\.com|www\.(gstatic|google|youtube)\.com|fonts\.gstatic\.com)$";
       } {
       type     = "simple";
       operand  = "dest.port";
       data     = "443";
       }];
  };};
};

flake.homeModules.discord = {
  programs.vesktop.enable  = true;
  stylix.targets.vesktop.enable = false; #BUG: unreadable
  };

}
