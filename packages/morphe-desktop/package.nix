{ perSystem = { pkgs, ... }: {
  packages.morphe-desktop = pkgs.callPackage ./_package.nix {};
};}
