{ flake.nixosModules.network_torrent = { pkgs, config, lib, ... }: {

services.opensnitch.rules.trr_aria_torrent = {
  name        = "trr_aria_torrent";
    enabled   = true;
    created   = "2018-04-07T14:13:27.903996051+02:00"; # silence logs
    action    = "allow";
    duration  = "always";
    operator  = {
      type    = "list";
      operand = "list";
      list    = [{
      type    = "simple";
      operand = "process.path";
      data    = "${lib.getExe pkgs.aria2}";
      } {
      type    = "regexp";
      operand = "user.id";
      data    = "^(${toString config.users_list.principalUserUid})$";
      }];
  };};

};}
