{ perSystem = { pkgs, ... }: {
  packages.wdotool = pkgs.callPackage ./_package.nix {};
};}
