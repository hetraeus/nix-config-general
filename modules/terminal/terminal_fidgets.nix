{ flake.homeModules.terminal_fidgets = { self, pkgs, ... }: {
  home.packages = [
    self.packages.${pkgs.stdenv.hostPlatform.system}.fidget-tty-clock
    self.packages.${pkgs.stdenv.hostPlatform.system}.fidget-tmatrix
    self.packages.${pkgs.stdenv.hostPlatform.system}.fidget-rain
    ];


};}
