{ perSystem = { pkgs, lib, ... }:
  let
    mkTorrentWebDashboard = { pkgs }:
      let
        script = pkgs.writeShellApplication {
          name          = "torrent-web-dashboard";
          runtimeInputs = [ pkgs.coreutils pkgs.gnused pkgs.xdg-utils ];
          text = ''
            protocol="ws" # unencrypted
            rpcHost="127.0.0.1"
            rpcPort="$(sed -n 's/^rpc-listen-port=//p' "$XDG_RUNTIME_DIR"/aria2/torrent.conf)"
            secret="$( sed -n 's/^rpc-secret=//p'      "$XDG_RUNTIME_DIR"/aria2/torrent.conf | tr -d '\n' | base64 | sed 's/=//g')"
            rpcInterface="jsonrpc"
            ${pkgs.lib.getExe' pkgs.xdg-utils "xdg-open"} \
            'file://${pkgs.ariang}/share/ariang/index.html#!'"/settings/rpc/set?protocol=$protocol&host=$rpcHost&port=$rpcPort&interface=$rpcInterface&secret=$secret"
          '';
        };
      in pkgs.makeDesktopItem {
        name        = "AriaNg";
        desktopName = "torrent remote webui web-ui download";
        icon        = "deluge-torrent";
        terminal    = false;
        categories  = [ "Utility" ];
        exec        = "${pkgs.lib.getExe script}";
      };
  in {
    # Default package (uses defaults)
    packages.torrent-web-dashboard = mkTorrentWebDashboard { inherit pkgs; };
    # Expose builder for overrides
    legacyPackages.torrent-web-dashboardWith = mkTorrentWebDashboard;
  };
}
