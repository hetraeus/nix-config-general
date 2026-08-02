{ flake.nixosModules.observability = { pkgs, lib, self, ... }: {
  boot.loader.systemd-boot.memtest86.enable = true;
  services.journald.extraConfig = ''
    # Compress=yes # commented out. Assume compressed file system
    SystemMaxUse=500M
    SystemKeepFree=1G
    MaxFileSec=1week
    '';
  environment.systemPackages = let
    vkmark-iGPU   = pkgs.makeDesktopItem {
      name        = "vkmark iGPU";
      desktopName = "vkmark integrated graphic card benchmark";
      exec        = "${lib.getExe pkgs.foot} -e ${lib.getExe' pkgs.coreutils "env"} DRI_PRIME=0 ${lib.getExe pkgs.vkmark}";
      terminal    = false;
      categories  = [ "System" ];
      icon        = "histogram-symbolic";
      };

    vkmark-dGPU   = pkgs.makeDesktopItem {
      name        = "vkmark dGPU";
      desktopName = "vkmark discrete graphic card benchmark";
      exec        = "${lib.getExe pkgs.foot} -e ${lib.getExe' pkgs.coreutils "env"} DRI_PRIME=1 ${lib.getExe pkgs.vkmark}";
      terminal    = false;
      categories  = [ "System" ];
      icon        = "histogram-symbolic";
      };

  in [
    # INFO: tuning tools related to specific setup are not listed here i.e. tuned

    pkgs.perf
    self.packages.${pkgs.stdenv.hostPlatform.system}.taint-check
    self.packages.${pkgs.stdenv.hostPlatform.system}.fmenu-display-test
    self.packages.${pkgs.stdenv.hostPlatform.system}.strace-fzf

    pkgs.strace
    pkgs.libsForQt5.qt5.qttools # qdbusviewer
    pkgs.inxi
    pkgs.procps
    pkgs.pstree
    pkgs.powertop
    pkgs.lsof
    #pkgs.lshw

    pkgs.glmark2
    pkgs.vkmark
    vkmark-dGPU
    vkmark-iGPU
    pkgs.kdiskmark

    #TODO: add back intel integrated GPU #  (pkgs.nvtopPackages.amd.override { intel = true; }) # NVIDIA id HEAVY
    ] ;

  services.sysprof.enable    = true;
  #programs.tuxclocker.enable = true;
  programs.iotop.enable      = true;

  # services.grafana.enable    = true;
  # services.grafana.openFirewall = true;
  # services.grafana.settings.analytics.feedback_links_enabled = false;
  # services.grafana.settings.analytics.reporting_enabled = false;
  # services.loki.enable       = true;
  # services.alloy.enable      = true;
  # services.loki.configFile   = ./1-Local-Configuration-Example.yaml ;
  # services.alloy.extraFlags  = [ "--disable-reporting" ];
};


flake.homeModules.observability = { pkgs, ... }: {
  programs.btop.enable = true;
  xdg.configFile."procps/toprc".source = ./toprc ;
  home.packages = [ pkgs.mission-center ];
};}
