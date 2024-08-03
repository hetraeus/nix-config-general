{ perSystem = { pkgs, self', ... }: {
  packages.fmenu-alltop = pkgs.writeShellApplication {
    name          = "fmenu-alltop";
    text          = builtins.readFile ./fmenu-alltop;
    runtimeInputs = [
      self'.packages.taint-check

      pkgs.coreutils
      pkgs.fzf pkgs.gnused pkgs.gawk pkgs.gnugrep
      pkgs.bat
      pkgs.foot
      pkgs.fastfetch
      pkgs.systemd
      # pkgs.perf
      pkgs.util-linux
      pkgs.btop
      pkgs.tuned
      pkgs.inxi
      pkgs.lshw
      pkgs.isd
      pkgs.powertop
      pkgs.sysctl
      pkgs.iotop-c
      pkgs.procps
      pkgs.libsForQt5.qt5.qttools
      # TODO add the others?
      # Utilities are declared in the system module.
      # The script checks if they are actually available
    ];
  };
};}
