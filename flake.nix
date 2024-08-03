{ description = "My NixOS flake";

inputs = {
# NOTE ! VARIABLES CANNOT BE USED IN THE INPUT BLOCK
# Inputs must be static
# But they can be composed via "follows"
# They can be overridden via flake.lock
# They can be abstracted via flake-parts or higher-level generators
#  nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  stylix.url         = "github:nix-community/stylix/release-26.05";
  sops-nix.url       = "github:Mic92/sops-nix";
  sops-nix.inputs.nixpkgs.follows     = "nixpkgs";
  home-manager.url = "github:nix-community/home-manager/release-26.05";
  home-manager.inputs.nixpkgs.follows = "nixpkgs";
  nix-index-database.url = "github:nix-community/nix-index-database";
  nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
  nvf.url            = "github:notashelf/nvf";
  nvf.inputs.nixpkgs.follows = "nixpkgs";
  multios-usb.url = "github:Mexit/MultiOS-USB";
  wrappers.url    = "github:Lassulus/wrappers";

  flake-parts.url = "github:hercules-ci/flake-parts";
  import-tree.url = "github:vic/import-tree";
  };

nixConfig = {
  extra-substituters = [
    "https://nix-community.cachix.org"
    # "https://devenv.cachix.org"
    ];
  extra-trusted-public-keys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    # "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    ];
  };

outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
  systems = [ "x86_64-linux" ];
  perSystem = { system, ... }: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };};
  imports = [
    (inputs.import-tree [ ./hosts ./users ./modules ./packages ])
     inputs.home-manager.flakeModules.home-manager
     ];
};}  
# use statix
