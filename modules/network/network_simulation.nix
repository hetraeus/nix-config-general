{ flake.nixosModules.network_simulation = { pkgs, ... }: {
  environment.systemPackages = [ pkgs.gns3-gui ];
};}
