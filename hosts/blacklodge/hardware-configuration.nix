{ flake.nixosModules.blacklodgeModules = { pkgs, lib, ... }: {

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.graphics.enable      = true;
  hardware.graphics.enable32Bit = true;
  hardware.graphics.extraPackages   = [               pkgs.libvdpau-va-gl ];
  hardware.graphics.extraPackages32 = [ pkgs.pkgsi686Linux.libvdpau-va-gl ];
  #hardware.amdgpu.opencl.enable     = true;
  # 2025-10-08 : cannot use amdvlk anymore. It even fails when = false because of an assertion

  # put console in initrd to use right keyboard mappings to unencrypt drives
  console.earlySetup = true;

  boot = {
    initrd.availableKernelModules   = [ "xhci_pci" "usb_storage" ];
    initrd.kernelModules            = [ ];
    kernelParams                    = [ ];
    kernelPackages                  = pkgs.linuxPackages_zen.extend ( lfinal: lprev: {
      opensnitch-ebpf = lprev.opensnitch-ebpf.overrideAttrs (old: {
        preBuild = old.preBuild or "" + ''
          makeFlagsArray+=(EXTRA_FLAGS="-Wno-microsoft-anon-tag -fms-extensions")
          '';});});
    loader.efi.canTouchEfiVariables = true;
    tmp.useTmpfs                    = true; # NOTE: Large Nix builds can fail if the mounted tmpfs is not large enough!
    };
  boot.loader.systemd-boot = {
    enable             = true;
    editor             = false;
    configurationLimit = 20;
    memtest86.enable   = true;
    };

  };
}
