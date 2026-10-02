{ perSystem = { pkgs, ... }: let
  clipboard-client = pkgs.callPackage ./_clipboard_client.nix {};
in {
  packages.clipboard-client = clipboard-client;
  packages.clipboard-server = pkgs.callPackage ./_clipboard_server.nix {};
};}
