{ flake.nixosModules.blacklodgeModules = { modulesPath, pkgs, lib, ... }: {

  imports = [
    # Set by nixos-generate-config for future uses
    # https://discourse.nixos.org/t/whats-the-rationale-behind-not-detected-nix/5403
    (modulesPath + "/installer/scan/not-detected.nix")
    ];

  hardware.graphics.enable      = true;
  hardware.graphics.enable32Bit = true;
  hardware.graphics.extraPackages   = [               pkgs.libvdpau-va-gl ];
  hardware.graphics.extraPackages32 = [ pkgs.pkgsi686Linux.libvdpau-va-gl ];
  #hardware.amdgpu.opencl.enable     = true;
  # 2025-10-08 : cannot use amdvlk anymore. It even fails when = false because of an assertion

  # put console in initrd to use right keyboard mappings to unencrypt drives
  console.earlySetup = true;

  boot = {
    initrd.availableKernelModules   = [ "bcachefs" "xhci_pci" "usb_storage" ];
    initrd.kernelModules            = [ ];
    kernelParams                    = [ ];
    kernelPackages                  = pkgs.linuxPackages_zen.extend ( lfinal: lprev: {
      opensnitch-ebpf = lprev.opensnitch-ebpf.overrideAttrs (old: {
        preBuild = old.preBuild or "" + ''
          makeFlagsArray+=(EXTRA_FLAGS="-Wno-microsoft-anon-tag -fms-extensions")
          '';});});
    supportedFilesystems            = [ "bcachefs" ];
    loader.efi.canTouchEfiVariables = true;
    tmp.useTmpfs                    = true; # NOTE: Large Nix builds can fail if the mounted tmpfs is not large enough!
    };
  boot.loader.systemd-boot = {
    enable             = true;
    editor             = false;
    configurationLimit = 20;
    memtest86.enable   = true;
    };

  fileSystems."/" = {
    device  = "/dev/sda2";
    fsType  = "bcachefs";
    # BUG: does not support swap file !
    options = [
      #"X-mount.subdir=@root/promote-001/"
      "lazytime"

      # INFO: fstrim.timer doesn't work
      # https://github.com/koverstreet/bcachefs/issues/721
      # note that it's enabled anyway with the hardware module
      "discard"
      ];
    };

  swapDevices = [ {
    device = "/dev/disk/by-label/swap_localpart";

    # WARN: Don’t hibernate when you have at least one swap partition with randomEncryption enabled!
    # We have no way to set the partition into which hibernation image is saved, so if your image ends up on an encrypted one you would lose it!
    # Do not use /dev/disk/by-{uuid,label}/... as your swap device when using randomEncryption as the UUIDs and labels will get
    # erased on every boot when the partition is encrypted. Best to use /dev/disk/by-partuuid/
    randomEncryption.enable = lib.mkForce false;
    } ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  };
}
