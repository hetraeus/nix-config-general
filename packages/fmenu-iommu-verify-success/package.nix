{ perSystem = { pkgs, ... }: {
  packages.fmenu-iommu-verify-success = pkgs.writeShellApplication {
    name          = "fmenu-iommu-verify-success";
    runtimeInputs = [ pkgs.findutils pkgs.coreutils pkgs.pciutils ];
    text = ''
      shopt -s nullglob
      for each_group in $(find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort --version-sort); do
        printf 'IOMMU Group %s:\n' "''${each_group##*/}"
        for each_device in "$each_group"/devices/*; do
          printf '\t%s\n' "$(lspci -nns "''${each_device##*/}")"
          done; done
    '';
  };
};}
