{ perSystem = { pkgs, ... }: {
  packages.fileicon = pkgs.callPackage ./_package.nix {};
};}
