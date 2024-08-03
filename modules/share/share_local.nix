{ flake.homeModules.share_local = { pkgs, ... } : {
  home.packages = [ pkgs.croc ];
};}
