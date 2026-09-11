{ flake.homeModules.desktop_niri = { pkgs, self, ... }: {
  home.packages = [
    pkgs.xwayland-satellite
    self.packages.${pkgs.stdenv.hostPlatform.system}.wlr-focus
    ];};
}
