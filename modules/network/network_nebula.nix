{ flake.nixosModules.network_nebula = { pkgs, config, ... } : {
  # INFO overlay network/vpn


  # services.opensnitch.rules.eee_kdeconnect_zero = {
  #   name        = "eee_kdeconnect_nix";
  #   created     = "2010-01-01T10:00:00.000000Z"; # silence logs
  #   enabled     = true;
  #   action      = "allow";
  #   duration    = "always";
  #   operator    = {
  #     type      = "list";
  #     operand   = "list";
  #     sensitive = false;
  #     list      = [{
  #       type    = "regexp";
  #       operand = "process.path";
  #       data    = "^/nix/store/[a-z0-9]{32}-kdeconnect-kde-.*/bin/.kdeconnectd-wrapped$";
  #       } {
  #       type    = "network";
  #       operand = "source.network";
  #       data    = "192.168.0.0/16";
  #       } {
  #       type    = "network";
  #       operand = "dest.network";
  #       data    = "192.168.0.0/16";
  #       }];
  #   };};
};
}
