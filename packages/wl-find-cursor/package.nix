{ perSystem = { pkgs, ... }: {
  packages.wl-find-cursor = pkgs.callPackage ./_wl-find-cursor.nix {};
};}
