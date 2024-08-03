# INFO: man 5 configuration.nix
# $ nixos-help
# https://search.nixos.org/options
{ inputs, self, ... }: let
  hostname = "blacklodge";
  system = "x86_64-linux";
  in {

flake.nixosConfigurations.${hostname} = inputs.nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = let
#    pkgs-unstable = import inputs.nixpkgs-unstable { inherit system; config.allowUnfree = true; };
  in { inherit inputs self; };

  modules = [
    self.nixosModules.mandatory
    self.nixosModules."${hostname}Modules"
    self.nixosModules.generalPurpUsers

    self.nixosModules.hardware
    self.nixosModules.power
    self.nixosModules.share_samba
    self.nixosModules.virtualisation_android
    self.nixosModules.virtualisation_lfhs
    self.nixosModules.virtualisation_pro

    self.nixosModules.network_diagnostics_deep
    self.nixosModules.network_offensive
    self.nixosModules.network_simulation
    self.nixosModules.network_torrent
    self.nixosModules.terminal_gui
    self.nixosModules.terminal_shell
    self.nixosModules.terminal_tty

    self.nixosModules.network_pan
    self.nixosModules.network_webbrowser
    self.nixosModules.network_connect_default

    self.nixosModules.dev_general
    self.nixosModules.dev_web
    self.nixosModules.virtualisation_containers
    self.nixosModules.security
    self.nixosModules.media_songrec
    self.nixosModules.media_mpv
    self.nixosModules.discord
    self.nixosModules.documentation
    self.nixosModules.maker
    self.nixosModules.pim
    self.nixosModules.gaming
    self.nixosModules.office
    self.nixosModules.backup
    self.nixosModules.i18n_en_de_it
    self.nixosModules.desktop_troubleshoot
    self.nixosModules.observability
    self.nixosModules.desktop_shell
    self.nixosModules.sound_control

    inputs.nixos-hardware.nixosModules.common-pc-ssd # this adds services.fstrim.enable

   # INFO: waiting for tuned https://github.com/NixOS/nixos-hardware/pull/1474
   { services.tuned.enable = true;}
   #inputs.nixos-hardware.nixosModules.common-pc-laptop


   # Intel, this adds:
   # hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
   # Note that upstream doesn't expose a Coffee Lake module in its flake
   inputs.nixos-hardware.nixosModules.common-cpu-intel
   inputs.nixos-hardware.nixosModules.common-gpu-intel

   # TODO enable this when hwinfo mappings are done
   # https://github.com/nix-community/nixos-facter/issues
   # Add the module to the flake
   #  inputs.nixos-facter-modules.nixosModules.facter
   #
   # Generate facter with
   # run0 nix run 'nixpkgs#nixos-facter' -- -o facter.json
   # config.facter.reportPath = ./facter.json;
   #
   # If you want to test out nixos-facter, you can add these dummy
   # values to make the configuration valid. Note that this likely won't boot if
   # it doesn't match your own partitioning
   # {
   #   users.users.root.initialPassword = "test password, don't use this";
   #   boot.loader.grub.devices = lib.mkForce [ "/dev/sda" ];
   #   fileSystems."/".device = lib.mkDefault "/dev/sda";
   # }
   # ...
   {
     networking.hostName = "${hostname}";
     programs.hyprland.enable             = true; # NEEDED AS A NIXOS MODULE by xdg portals
     programs.hyprland.withUWSM           = true;
     security.pam.services.hyprlock       = {};
     security.pam.services.swaylock       = {};

     # Some programs need SUID wrappers, can be configured further or are
     # started in user sessions.
     # programs.gnupg.agent = {
     #   enable = true;
     #   enableSSHSupport = true;
     #   };
     # sys_virtualisation_pro.passthrough.enable = true;
     # sys_virtualisation_pro.passthrough.iommuKernelParams = [
     #   # https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Enabling_IOMMU
     #   # https://docs.redhat.com/en/documentation/red_hat_virtualization/4.1/html/installation_guide/appe-configuring_a_hypervisor_host_for_pci_passthrough

     #   # AMD parameter "amd_iommu=on" is not mandatory
     #   # If intel_iommu=on / amd_iommu=on works, try use intel_iommu=pt / amd_iommu=pt
     #   # which enables IOMMU only for devices used in passthrough and provides better host performance
     #   # 2025-11-16 intel_iommu=pt doesn't work
     #   "intel_iommu=on"

     #   # PCI addresses:
     #   # nix run 'nixpkgs#'pciutils -- -nn | grep --color=always '\[[0-9a-f]*:[0-9a-f]*\]'
     #   "vfio-pci.ids=1002:6900"
     #   ];
  }];
};}
