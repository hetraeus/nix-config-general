{ flake.nixosModules.network_pan = { pkgs, config, ... } : {
  hardware.bluetooth.enable = true;
  services.blueman.enable   = true;

  # kdeconnect firewall rules
  networking.firewall.allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
  networking.firewall.allowedUDPPortRanges = config.networking.firewall.allowedTCPPortRanges;

  services.opensnitch.rules.eee_kdeconnect_one = {
    name        = "eee_kdeconnect_nix";
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
        operand  = "process.path";
        data     = "^/nix/store/[a-z0-9]{32}-kdeconnect-kde-.*/bin/.kdeconnectd-wrapped$";
         } {
         type    = "network";
         operand = "source.network";
         data    = "192.168.1.0/16";
         } {
         type    = "network";
         operand = "dest.network";
         data    = "192.168.1.0/16";
         }];
    };};

  services.opensnitch.rules.eee_kdeconnect_zero = {
    name        = "eee_kdeconnect_nix";
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
        operand  = "process.path";
        data     = "^/nix/store/[a-z0-9]{32}-kdeconnect-kde-.*/bin/.kdeconnectd-wrapped$";
         } {
         type    = "network";
         operand = "source.network";
         data    = "192.168.0.0/16";
         } {
         type    = "network";
         operand = "dest.network";
         data    = "192.168.0.0/16";
         }];
    };};

  services.opensnitch.rules.eee_kdeconnect_255 = {
    name        = "eee_kdeconnect_255";
    created     = "2011-01-01T10:00:00.003996051+02:00"; # silence logs
    enabled     = true;
    action      = "deny";
    duration    = "always";
    operator    = {
      type      = "list";
      operand   = "list";
      sensitive = false;
      list      = [{
       type     = "regexp";
       operand  = "process.path";
       data     = "^/nix/store/[a-z0-9]{32}-kdeconnect-kde-.*/bin/.kdeconnectd-wrapped$";
        } {
        type    = "simple";
        operand = "dest.ip";
        data    = "255.255.255.255";
        }];
    };};

};

flake.homeModules.network_pan = { self, pkgs, ... }: {

  # INFO: kdeconnect
  # remember open tcp and udp ports from 1714 to 1764 from system configuration
  # WARN: 2025-02-09 remote impulse i.e. remote mouse and keyboard doesn't work in hyprland
  services.kdeconnect.enable       = true;
  services.kdeconnect.indicator    = true;
  home.packages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.find-phone ];

};}
