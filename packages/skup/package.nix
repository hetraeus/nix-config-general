{ perSystem = { pkgs, self', ... }: {
    packages.skup = pkgs.callPackage ./_package.nix {
      inherit (self'.packages) board_list_rasi;
    };
  };
}
