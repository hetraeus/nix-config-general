{ perSystem = { pkgs, lib, ... }: {
  packages.gping-default = let
    script = pkgs.writeShellApplication {
      name          = "gping-gateway-dns-example";
      runtimeInputs = [ pkgs.gping pkgs.gawk pkgs.jq pkgs.iproute2 pkgs.systemdMinimal ];
      text = ''
        ALL_TARGETS=( "$(ip -json route list default | jq --raw-output '.[].gateway')" )
        [[ -n "''${ALL_TARGETS[0]}" ]] &&
          ALL_TARGETS+=("$(resolvectl status | awk 'BEGIN { FS = "[#:]" }; /Current DNS Server:/{gsub(/ /,""); print $2; exit}')")
        [[ -n "''${ALL_TARGETS[1]}" ]] &&
          ALL_TARGETS+=("example.com")
        gping --watch-interval 1 "''${ALL_TARGETS[@]}"
      '';
    };
    desktopItem = pkgs.makeDesktopItem {
      name        = "gping";
      exec        = ''${lib.getExe pkgs.kitty} --app-id="kitty_floating" --hold ${lib.getExe script}'';
      desktopName = "gping";
      genericName = "gateway google.com dns router 10.0.0.0 192.168. 172.16";
      categories  = [ "Utility" ];
      icon        = "send-to";
    };
  in pkgs.buildEnv {
    name             = "gping-default-wrapper";
    paths            = [ script desktopItem ];
    meta.mainProgram = "term-gping-gateway-dns_example";
  };
};}
