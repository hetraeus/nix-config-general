{ flake.nixosModules.network_connect_default = { pkgs, config, lib, ... }: let

  # CLoudflare
  # "1.1.1.1#one.one.one.one"
  # "1.0.0.1#one.one.one.one"

  # DNS4EU
  # dnsv4_1 = "86.54.11.13";
  # dnsv4_2 = "86.54.11.213";
  # dnsv6_1 = "2a13:1001::86:54:11:13";
  # dnsv6_2 = "2a13:1001::86:54:11:213";

  dns_1 = "9.9.9.9";
  dns_2 = "2620:fe::fe";

  dns_fall1 = "149.112.112.112";
  dns_fall2 = "2620:fe::9";

in {

  # environment.shellAliases.ip = "ip --color ";

  # INFO: Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlan0.useDHCP = lib.mkDefault true;
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  networking.wireless.iwd.enable = true;
  # WARN: usePredictableInterfaceNames (default true)
  # doesn't work with iwd because it causes a
  # race condition with systemd-networkd.
  # this is the override in case systemd-networkd is enabled
  systemd.network.links."80-iwd" = lib.mkIf config.systemd.network.enable (lib.mkForce {});


  # network time protocol
  services.opensnitch.rules.fff_sync_time = {
    name        = "fff_sync_time";
    enabled     = true;
    created     = "2025-02-07T20:05:02.000000Z"; # silence logs
    action      = "allow";
    duration    = "always";
    operator    = {
      type      = "list";
      operand   = "list";
      list      = [{
        type    = "simple";
        operand = "protocol";
        data    = "udp";
        } {
        type    = "simple";
        operand = "process.path";
        data    = "${pkgs.systemd}/lib/systemd/systemd-timesyncd";
        } {
        type    = "simple";
        operand = "dest.port";
        data    = "123";
        }];
    };};


  services.opensnitch.rules.bbb_let_apps_to_resolve = {
    name        = "bbb_let_apps_to_resolve";
    enabled     = true;
    created     = "2025-02-07T20:05:02.000000Z"; # silence logs
    action      = "allow";
    duration    = "always";
    operator    = {
      type      = "list";
      operand   = "list";
      list = [{
        type = "simple";
        operand = "protocol";
        data ="udp";
        } {
        type = "simple";
        operand = "dest.port";
        data = "53";
        } {
        type = "network";
        operand = "source.network";
        data = "127.0.0.0/8";
        } {
        type = "simple";
        operand = "dest.ip";
        data = "127.0.0.53";
        }];
    };};

  services.opensnitch.rules.bcc_let_dns_client_to_resolve = let
    escapeIp = ip: lib.replaceStrings ["."] ["\\."] ip;
  in {
    name        = "bcc_let_dns_client_to_resolve";
    enabled     = true;
    created     = "2011-01-01T10:00:00.000000Z"; # silence logs
    action      = "allow";
    duration    = "always";
    operator    = {
      type      = "list";
      operand   = "list";
      list      =  [{
        type    = "regexp";
        operand = "process.path";
        data    = "^/nix/store/[a-z0-9]{32}-systemd-.*/lib/systemd/systemd-resolved$";
        } {
        type    = "regexp";
        operand = "dest.port";
        data    = "^(853|5353)$";
        } {
        type    = "regexp";
        operand = "dest.ip";
        data = "^(${escapeIp "192.168.1.1"}|${escapeIp dns_1}|${escapeIp dns_2}|${escapeIp dns_fall1}|${escapeIp dns_fall2})$";
        } {
        type    = "simple";
        operand = "user.id";
        data    = "153";
        }];
    };};


  services.opensnitch.rules.conn_cloudflare = {
    name        = "conn_cloudflare";
    enabled     = true;
    created     = "2011-01-01T10:00:00.000000Z"; # silence logs
    action      = "allow";
    duration    = "always";
    operator    = {
      type      = "list";
      operand   = "list";
      list      =  [{
        type    = "regexp";
        operand = "dest.host";
        data    = "^((turn|stun)\.cloudflare\.com|stun(|1|2|3)\.l\.google\.com)$";
        }];
    };};

  networking.nameservers = [
      "${dns_1}"
      "${dns_2}"
      ];
  services.resolved.enable           = true;
  services.resolved.settings.Resolve = {
    FallbackDNS     = [ dns_fall1 dns_fall2 ];
    Domains         = [ "~." ];
    DNSSEC          = "true";
    DNSOverTLS      = "true";

  # https://web.archive.org/web/20250203183242/https://attack.mitre.org/techniques/T1557/001/
  # what about NetBIOS, mdns, avahi ?
    LLMNR           = "false";
    };


  services.opensnitch.rules.rra_disable_multicast_ipv4 = {
    name        = "rra_disable_multicast_ipv4";
    enabled     = true;
    created     = "2018-04-07T14:13:27.903996051+02:00"; # silence logs
    action      = "deny";
    duration    = "always";
    operator    = {
      type      = "list";
      operand   = "list";
      list      = [{
        type    = "network";
        operand = "dest.network";
        data    = "224.0.0.0/4";
        }];
    };};

  services.opensnitch.rules.rra_disable_multicast_ipv6 = {
    name        = "rra_disable_multicast_ipv6";
    enabled     = true;
    created     = "2018-04-07T14:13:27.903996051+02:00"; # silence logs
    action      = "deny";
    duration    = "always";
    operator    = {
      type      = "list";
      operand   = "list";
      list      = [{
        type    = "network";
        operand = "dest.network";
        data    = "ff00::/8";
        }];
    };};

  services.opensnitch.rules.rra_disable_unicast_ipv6 = {
    name        = "rra_disable_unicast_ipv6";
    enabled     = true;
    created     = "2018-04-07T14:13:27.903996051+02:00"; # silence logs
    action      = "deny";
    duration    = "always";
    operator    = {
      type      = "list";
      operand   = "list";
      list      = [{
        type    = "network";
        operand = "dest.network";
        data    = "fe80::/10";
        }];
    };};

  services.opensnitch.enable = true; # WARN: too much trouble, crashes
  networking.firewall.enable = true;

  programs.captive-browser.enable    = true;
  programs.captive-browser.interface = "wlan0";
  programs.captive-browser.dhcp-dns  = "printf ${dns_1}";

  services.opensnitch.rules.aee_allow_internal_sockets_ipv4 = {
    name        = "aee_allow_internal_sockets_ipv4";
    enabled     = true;
    created     = "2018-04-07T14:13:27.903996051+02:00"; # silence logs
    action      = "allow";
    duration    = "always";
    operator    = {
      type      = "list";
      operand   = "list";
      list      = [{
        type    = "simple";
        operand = "protocol";
        data    = "tcp";
        } {
        type    = "network";
        operand = "source.network";
        data    = "127.0.0.1/8";
        } {
        type    = "network";
        operand = "dest.network";
        data    = "127.0.0.1/8";
        }];
    };};


  services.opensnitch.rules.aep_allow_internal_sockets_ipv6 = {
    name        = "aep_allow_internal_sockets_ipv6";
    enabled     = true;
    created     = "2018-04-07T14:13:27.903996051+02:00"; # silence logs
    action      = "allow";
    duration    = "always";
    operator    = {
      type      = "list";
      operand   = "list";
      list      = [{
        type    = "simple";
        operand = "protocol";
        data    = "tcp6";
        } {
        type    = "network";
        operand = "source.network";
        data    = "::1/128";
        } {
        type    = "network";
        operand = "dest.network";
        data    = "::1/128";
        }];
    };};

  environment.systemPackages = [ pkgs.w3m ];

  # services.opensnitch.rules.abb_wget = {
  #   name      = "abb_wget";
  #   enabled   = true;
  #   action    = "allow";
  #   duration  = "always";
  #   operator  = {
  #     type    = "simple";
  #     operand = "process.path";
  #     data    = "${lib.getExe pkgs.wget}";
  #     };};

  services.opensnitch.rules.aaa_curl = {
    name      = "aaa_curl";
    enabled   = true;
    created   = "2018-04-07T14:13:27.903996051+02:00"; # silence logs
    action    = "allow";
    duration  = "always";
    operator  = {
      type    = "simple";
      operand = "process.path";
      data    = "${lib.getExe pkgs.curl}";
      };};


  services.opensnitch.rules.acc_w3m = {
    name      = "acc_w3m";
    enabled   = true;
    created   = "2018-04-07T14:13:27.903996051+02:00"; # silence logs
    action    = "allow";
    duration  = "always";
    operator  = {
      type    = "simple";
      operand = "process.path";
      data    = "${lib.getExe pkgs.w3m}";
      };};

  services.opensnitch.rules.zaa_block_tmp_var_shm = {
    name      = "zaa_block_tmp_var_shm";
    created   = "2018-04-07T14:13:27.903996051+02:00"; # silence logs
    enabled   = true;
    action    = "deny";
    duration  = "always";
    operator  = {
      type    = "regexp";
      operand = "process.path";
      data    = "^(/tmp/|/var/tmp/|/dev/shm/|/var/run|/var/lock).*";
      };};
 };

flake.homeModules.network_connect_default = { lib, pkgs, self, ... }: let
  fmenu-network = self.packages.${pkgs.stdenv.hostPlatform.system}.fmenu-network;
  gping-default = self.packages.${pkgs.stdenv.hostPlatform.system}.gping-default;

in {

  home.packages = [
    fmenu-network
    gping-default
    self.packages.${pkgs.stdenv.hostPlatform.system}.gateway-webui
    ];
  programs.trippy.enable = true;

  systemd.user.services.network_dashboard = let
    network_kitty_session = let

      status_rfkill = pkgs.writeShellApplication {
        runtimeInputs = [ pkgs.gnugrep pkgs.coreutils pkgs.util-linux ];
        name = "status_rfkill";
        text = ''
          while true; do
             printf "\x1bc" # clears the screen but doesn't fail under systemd

            rfkill | grep --color --extended-regexp " blocked|^"
            printf "\n rfkill unblock all ? (y) "
            read -r -t 60 CONFIRMATION || true # true is needed because read failure exits the script !

            [[ "$CONFIRMATION" == y ]] && {
              rfkill unblock all
              printf '%(%H:%M)T: all unblocked!\n'
              sleep 2
              }

            done
          ''; };

     in pkgs.writeText "network_kitty_session" ''
      layout tall
      enabled_layouts tall:bias=74;full_size=1,stack,grid
      launch sh -c "${lib.getExe fmenu-network}"
      launch "${lib.getExe status_rfkill}"
      #launch sh -c "~/.local/bin/scripts/mooc_play"
      launch kitty  @ focus-window --match=cmdline:fmenu-network$
      '';
  in {
    path = { PATH = [ gping-default ]; };
    Service.ExecStart = "${lib.getExe pkgs.kitty} --app-id='network_dashboard' --title='🖧 network' --session=${network_kitty_session}";
    Unit.Description  = "network_dashboard";
    Unit.After        = [ "graphical-session.target" ] ;
    Unit.Wants        = [ "graphical-session.target" ] ;
    Install.WantedBy  = [ "graphical-session.target" ] ;
    };
};}
