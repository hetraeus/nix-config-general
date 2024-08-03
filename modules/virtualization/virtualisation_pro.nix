{ flake.nixosModules.virtualisation_pro = { pkgs, lib, config, self, ... }: let
  cfg = config.sys_virtualisation_pro;

in {

options.sys_virtualisation_pro = {
  passthrough.enable = lib.mkEnableOption "passthrough switch";
  passthrough.iommuKernelParams = lib.mkOption {
    type = lib.types.nonEmptyListOf lib.types.str;
    default = [];
    description = "list of passthrough parameters (at least one required)";
  };
};

config = {

  environment.systemPackages = [ pkgs.quickemu ];

  programs.virt-manager.enable              = true;
  virtualisation.libvirtd.enable            = true;
  virtualisation.libvirtd.qemu.runAsRoot    = false;
  virtualisation.libvirtd.qemu.swtpm.enable = true; # mandatory for Microsoft Windows 11+
  # Install the SPICE USB redirection helper with setuid privileges.inherit
  # This allows unprivileged users to pass USB devices connected to this
  # machine to libvirt VMs, both local and remote.
  # WARN: This allows users arbitrary access to USB devices.
  # virtualisation.spiceUSBRedirection.enable = true;

  #users.users."${config.users_list.principalUser}".extraGroups  = [ "libvirtd" ];     # libvirt virtual machines without password request

  specialisation.gpupassthrough.configuration = lib.mkIf cfg.passthrough.enable {
    environment.systemPackages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.fmenu-iommu-verify-success ];
    boot.kernelParams = cfg.passthrough.iommuKernelParams;

    # WARN: VFIO modules must be loaded BEFORE other drivers in use
    # e.g.: early modesetting drivers, such as i915, amdgpu, radeon, nouveau, etc.
    boot.initrd.kernelModules = [ "vfio_pci" "vfio" "vfio_iommu_type1" ];
    };

};};}
