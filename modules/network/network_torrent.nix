{ flake.nixosModules.network_torrent = { pkgs, config, lib, ... }: {

services.opensnitch.rules.trr_aria_torrent = {
  name      = "trr_aria_torrent";
  enabled   = true;
  created   = "2010-01-01T10:00:00.000000Z"; # silence logs
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
