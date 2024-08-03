{ perSystem = { pkgs, ... }: {
  packages.fmenu-network = pkgs.writeShellApplication {
    name               = "fmenu-network";
    text               = builtins.readFile ./fmenu-network;
    excludeShellChecks = [ "SC1091" ];
    runtimeInputs = [
      pkgs.coreutils
      pkgs.moreutils
      pkgs.gawk
      pkgs.jq
      pkgs.gnugrep
      pkgs.gnused
      pkgs.findutils
      pkgs.fzf
      pkgs.gum
      pkgs.bat
      pkgs.neovim
      pkgs.xdg-utils
      pkgs.foot
      pkgs.systemd
      pkgs.iwd
      pkgs.curl
      # 2026-05-03 build failure
      # pkgs.termshark
      # pkgs.wireshark
      pkgs.iw
      pkgs.iputils # ping
      pkgs.gping
      pkgs.dig # nslookup
      pkgs.ipcalc
      pkgs.rdap
      pkgs.mtr
      pkgs.nmap
      pkgs.iana-etc
      pkgs.bandwhich
      pkgs.librespeed-cli
      pkgs.speedtest-go
      pkgs.zbar
      pkgs.iproute2 # ss
      pkgs.netdiscover
      pkgs.trippy
      # mpv?? neovim ??
      # TODO: firewall
      # pkgs.azure-cli
      # pkgs.awscli2
      # pkgs.google-cloud-sdk-gce
    ];
  };
};}
