{ flake.nixosModules.geography = { ... }: {

  services.opensnitch.rules.maps_kde = {
    name        = "maps_kde";
    created     = "2010-01-01T10:00:00.000000Z"; # silence logs
    enabled     = true;
    action      = "allow";
    duration    = "always";
    operator    = {
      type      = "list";
      operand   = "list";
      sensitive = false;
      list      = [{
        type    = "regexp";
        operand = "dest.host";
        data    = "^(maps\.kde\.org)$";
        } {
        type     = "simple";
        operand  = "dest.port";
        data     = "443";
        }];
    };};

};

flake.homeModules.geography = { pkgs, ... }: {

  home.packages = [
    pkgs.kdePackages.marble
    ];
   };
}
