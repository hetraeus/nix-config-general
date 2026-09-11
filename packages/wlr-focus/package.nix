{ perSystem = { pkgs, ... }: {
  packages.wlr-focus = pkgs.callPackage ./_package.nix {};
};}
