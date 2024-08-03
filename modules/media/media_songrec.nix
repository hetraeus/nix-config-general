{ flake.nixosModules.media_songrec = { pkgs, config, lib, ... }: {

services.opensnitch.rules.sng_songrec = {
  name        = "sng_songrec";
    enabled   = true;
    created     = "2018-04-07T14:13:27.903996051+02:00"; # silence logs
    action    = "allow";
    duration  = "always";
    operator  = {
      type    = "list";
      operand = "list";
      list    = [{
      type    = "simple";
      operand = "process.path";
      data    = "${lib.getExe pkgs.songrec}";
      } {
      type    = "regexp";
      operand = "dest.port";
      data    = "^443$";
      } {
      type    = "regexp";
      operand = "dest.host";
      data    = "^(is1-ssl\.mzstatic\.com|amp\.shazam\.com)$";
      } {
      type    = "regexp";
      operand = "user.id";
      data    = "^(${toString config.users_list.principalUserUid})$";
      }];
  };};
};

flake.homeModules.media_songrec = { lib, pkgs, ... }: {
  home.packages = [ pkgs.songrec ];
  };
}
