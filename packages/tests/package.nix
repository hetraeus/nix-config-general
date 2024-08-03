{ perSystem = { pkgs, ... }: {
  packages.test = pkgs.callPackage ./_package.nix {};
};}
