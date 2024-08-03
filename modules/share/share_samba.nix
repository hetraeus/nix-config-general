{ flake.nixosModules.share_samba = { config, ... }: {

# INFO: man 5 smb.conf
# to allow my_user to be authenticated on the samba server, add their password using
#   smbpasswd -a my_user
# list users:
#  pdbedit -L -v
# WARN: not using avahi/zeroconf/multicast because of security concerns

services.samba = {
  enable = true;
  openFirewall = true;
  };

# services.samba-wsdd = { # advertise the shares to Windows hosts
#   enable = true;
#   openFirewall = true;
# };

services.samba.usershares.enable = true;
services.samba.settings = {
  global = {
    "workgroup"      = "WORKGROUP";
    "server string"  = "smbnix";
    "netbios name"   = "smbnix";
    "security"       = "user";
    "use sendfile"   = "yes";
    #"max protocol"  = "smb2";
    # note: localhost is the ipv6 localhost ::1
    "hosts allow"    = "192.168.0. 127.0.0.1 localhost";
    "hosts deny"     = "0.0.0.0/0";
    "guest account"  = "nobody";
    "map to guest"   = "never"; # failed authentication = no entry and no guest entry
    };

  # "public" = {
  #   "path" = "/mnt/Shares/Public";
  #   "browseable" = "yes";
  #   "read only" = "no";
  #   "guest ok" = "yes";
  #   "create mask" = "0644";
  #   "directory mask" = "0755";
  #   "force user" = "username";
  #   "force group" = "groupname";
  # };
  # "private" = {
  #   "path" = "/mnt/Shares/Private";
  #   "browseable" = "yes";
  #   "read only" = "no";
  #   "guest ok" = "no";
  #   "create mask" = "0644";
  #   "directory mask" = "0755";
  #   "force user" = "username";
  #   "force group" = "groupname";
  # };
};


services.opensnitch.rules.smb_enable_nmb = {
  name        = "smb_enable_nmbd";
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
      data    = "${config.services.samba.package}/bin/nmbd";
      } {
      type    = "regexp";
      operand = "source.port";
      data    = "^(137|138)$";
      } {
      type    = "regexp";
      operand = "dest.port";
      data    = "^(137|138)$";
      } {
      type    = "simple";
      operand = "protocol";
      data    = "udp";
      } {
      type    = "regexp";
      operand = "dest.ip";
      data    = "^(192\.168\.(1|122)\.255)$";
      }];
  };};

};}
