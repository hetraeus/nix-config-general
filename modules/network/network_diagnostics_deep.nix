{ flake.nixosModules.network_diagnostics_deep = { pkgs, lib, ... }: {
  programs.mtr.enable = true;
  programs.bandwhich.enable = true;
  # programs.wireshark.enable  = true;
  programs.wireshark.usbmon.enable = true;
  environment.systemPackages = [
    # pkgs.termshark
    # pkgs.wireshark
    pkgs.nftables

    pkgs.pwru
    pkgs.iw
    pkgs.iputils # ping
    pkgs.gping
    pkgs.dig # nslookup
    pkgs.ipcalc
    pkgs.rdap
    pkgs.mtr
    pkgs.nmap
    pkgs.iana-etc
    pkgs.librespeed-cli
    pkgs.speedtest-go
    pkgs.zbar
    pkgs.iproute2 # ss
    pkgs.netdiscover
    ];
};}
