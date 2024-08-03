{ flake.nixosModules.mandatory = { ... }: {
  imports = [
    ./_mandatory_os_troubles.nix
    ./_mandatory_os_compatibility.nix
    ./_mandatory_os_editors.nix
    ./_mandatory_os_block_telemetry.nix
    ./_mandatory_os_i18n.nix
    ./_mandatory_os_nix.nix
    ];

};
flake.homeModules.mandatory = { ... }: {
  imports = [
    ./_mandatory_hm_block_telemetry.nix
    ./_mandatory_hm_troubles.nix
    ];
};}
