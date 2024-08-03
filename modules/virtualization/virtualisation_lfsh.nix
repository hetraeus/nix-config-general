{ flake.nixosModules.virtualisation_lfhs = { pkgs, ... }: {
  environment.systemPackages = [ pkgs.distrobox ];
  # keep nix-ld elsewhere

};}
