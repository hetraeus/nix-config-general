{ flake.nixosModules.network_offensive = { pkgs, ... }: {
  environment.systemPackages = [ pkgs.bettercap pkgs.burpsuite pkgs.rockyou ];

};}
