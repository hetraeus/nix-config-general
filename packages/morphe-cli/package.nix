{ perSystem = { pkgs, ... }: {
  packages.morphe-cli = pkgs.callPackage ./_package.nix {};
};}
