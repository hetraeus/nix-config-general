{ perSystem = { pkgs, ... }: {
  packages.cursor-ring = pkgs.callPackage ./_package.nix {};
};}
