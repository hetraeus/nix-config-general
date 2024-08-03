{ flake.homeModules.dw_aria = { lib, pkgs, config, self, ... } : let

  dw_add = self.packages.${pkgs.stdenv.hostPlatform.system}.dw-add;
  restart_service = pkgs.writeShellApplication {
    name    = "restart_service";
    runtimeInputs = [ pkgs.systemd pkgs.libnotify ];
    text    = ''
      systemctl            --user restart           "$1"
      systemctl --no-pager --user status            "$1"
      systemctl --no-pager --user is-active --quiet "$1".service \
      && {
        app_b64="$(base64 --wrap=0 <<< "$1")"
        printf $'\e]99;i=1:f=%s;%s\n%s started\e\\' "$app_b64" "$1" "$2"
        }
    '';
   };

in {
  home.packages = let
    pkgs_pinned_1 = import (fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/e6f23dc08d3624daab7094b701aa3954923c6bbb.tar.gz";
      sha256 = "0m0xmk8sjb5gv2pq7s8w7qxf7qggqsd3rxzv3xrqkhfimy2x7bnx";
      }) { system = pkgs.stdenv.hostPlatform.system; };

    in [
      pkgs.aria2
      (self.legacyPackages.${pkgs.stdenv.hostPlatform.system}.torrent-web-dashboardWith {
        pkgs = pkgs_pinned_1;
        })
    ];

 systemd.user.services.aria2 = {
    Install.WantedBy = [ "multi-user.target" ];
    Unit = {
      Description = "Aria2 Daemon";
      After       = "network.target";
      };

    Service         = {
      Type          = "exec";
      ExecStart     = "${lib.getExe  pkgs.aria2} --conf-path=%t/aria2/torrent.conf"; # NOTE %t = %r in sops .path
      ExecStartPost = "${lib.getExe' pkgs.coreutils "sleep"} .2";
      PrivateTmp    = "yes";  # Protects against accidental cross-process temp file clashes
  #    InaccessiblePaths     = "/boot"; # aria2 will mount /boot :(
      };
  };

  home.shellAliases.aaq = ''
    ${lib.getExe' pkgs.systemd     "systemctl"} --user stop  aria2;
    ${lib.getExe' pkgs.systemd     "systemctl"} --no-pager --user status  aria2;
    ${lib.getExe' pkgs.libnotify "notify-send"} --app-name=aria2 aria2 '∬ ▪ stopped'
    '';
  home.shellAliases.aaa = ''
    ${lib.getExe restart_service} aria2 ∬
    '';

  # WARN: don't put a firefox / browser bookmark because it cannot have the credentials in it

  xdg.desktopEntries.aria2_torrent = {
    name         = "aria2_torrent";
    genericName  = "torrent download restart";
    icon         = "deluge-torrent"; # just the deluge icon, not the actual app
    terminal     = false;
    categories   = [ "Utility" ];
    exec         = "${lib.getExe restart_service} aria2 ∬";
    };


  xdg.desktopEntries.dwCadBook = {
    name        = "dw 🔖 car audiobooks";
    exec        = "${lib.getExe dw_add} /run/media/\\\$USER/BLISS_ONLIN/Books CLIPBOARD";
    terminal    = false;
    categories  = [ "Network" ];
    genericName = "torrent download";
    icon        = "emblem-downloads";
    };

  xdg.desktopEntries.dwMusVid = {
    name        = "dw 👯 musical video";
    exec        = "${lib.getExe dw_add} ${config.xdg.userDirs.music}/Musical videos CLIPBOARD";
    terminal    = false;
    categories  = [ "Network" ];
    genericName = "torrent download";
    icon        = "emblem-downloads";
    };

  xdg.desktopEntries.dwCarMus  = {
    name        = "dw 🚗 car music";
    exec        = "${lib.getExe dw_add} /run/media/\\\$USER/BLISS_ONLIN/Multi CLIPBOARD";
    terminal    = false;
    categories  = [ "Network" ];
    genericName = "torrent download";
    icon        = "emblem-downloads";
    };

  xdg.desktopEntries.dwChoose  = {
    name        = "dw    choose";
    exec        = "${lib.getExe dw_add} choose_dest CLIPBOARD";
    terminal    = false;
    categories  = [ "Network" ];
    genericName = "torrent download";
    icon        = "emblem-downloads";
    };

  xdg.desktopEntries.dwFolder  = {
    name        = "dw 󰉍  dwload folder";
    exec        = "${lib.getExe dw_add} ${config.xdg.userDirs.download} CLIPBOARD";
    terminal    = false;
    categories  = [ "Network" ];
    genericName = "torrent download";
    icon        = "emblem-downloads";
    };

  xdg.desktopEntries.dwMovies  = {
    name        = "dw 󱉺  movie";
    exec        = "${lib.getExe dw_add} ${config.xdg.userDirs.videos}/zz_latest CLIPBOARD";
    terminal    = false;
    categories  = [ "Network" ];
    genericName = "torrent download film";
    icon        = "emblem-downloads";
    };

  xdg.desktopEntries.dwMus = {
    name        = "dw 󰎇 music";
    exec        = "${lib.getExe dw_add} ${config.xdg.userDirs.music}/.temp CLIPBOARD";
    terminal    = false;
    categories  = [ "Network" ];
    genericName = "torrent download";
    icon        = "emblem-downloads";
    };

};}
