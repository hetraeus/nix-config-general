{ flake.nixosModules.mandatory = { modulesPath, ... }: {
  imports = [
    ./_mandatory_os_troubles.nix
    ./_mandatory_os_compatibility.nix
    ./_mandatory_os_editors.nix
    ./_mandatory_os_block_telemetry.nix
    ./_mandatory_os_i18n.nix
    ./_mandatory_os_nix.nix
    # Set by nixos-generate-config for future uses
    # https://discourse.nixos.org/t/whats-the-rationale-behind-not-detected-nix/5403
    (modulesPath + "/installer/scan/not-detected.nix")


    ];

};
flake.homeModules.mandatory = { ... }: {
  imports = [
    ./_mandatory_hm_block_telemetry.nix
    ./_mandatory_hm_troubles.nix
    ];
};}
