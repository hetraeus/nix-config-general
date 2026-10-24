{ perSystem = { pkgs, ... }: {
    packages.rescuezilla = pkgs.callPackage ./_package.nix {};
  };
}
