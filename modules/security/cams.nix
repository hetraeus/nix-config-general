{ flake.homeModules.security_cams = { self, pkgs, ... } : {
  home.packages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.fmenu-watch-cams001 ];
};}
