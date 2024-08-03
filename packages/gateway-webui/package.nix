{ perSystem = { pkgs, lib, ... }: {
  packages.gateway-webui = let
    script = pkgs.writeShellApplication {
      name          = "gateway-webui";
      runtimeInputs = [ pkgs.iproute2 pkgs.jq pkgs.xdg-utils ];
      text = ''
        xdg-open "http://$(ip -json route list default | jq --raw-output '.[].gateway')"
      '';
    };
  in pkgs.makeDesktopItem {
    name        = "gateway-webui";
    desktopName = "gateway web-ui";
    genericName = "router webui web-ui firewall 10.0.0.0 192.168. 172.16";
    icon        = "network-server";
    terminal    = false;
    categories  = [ "Utility" ];
    exec        = "${lib.getExe script}";
  };
};}
