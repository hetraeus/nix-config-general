{ perSystem = { pkgs, ... }: {
  packages.clipboard-server = pkgs.callPackage ./_clipboard_server.nix {};
  packages.clipboard-client = pkgs.callPackage ./_clipboard_client.nix {};
};}
