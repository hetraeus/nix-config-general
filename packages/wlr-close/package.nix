{ perSystem = { pkgs, ... }: {
  packages.wlr-close = pkgs.callPackage ./_package.nix {};
};}
