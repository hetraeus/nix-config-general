{ description = "My NixOS flake";

inputs = {
# NOTE ! VARIABLES CANNOT BE USED IN THE INPUT BLOCK
# Inputs must be static
# But they can be composed via "follows"
# They can be overridden via flake.lock
# They can be abstracted via flake-parts or higher-level generators
  nixpkgs.url        = "github:NixOS/nixpkgs/nixos-26.05";
  omniflake.url      = "github:fzakaria/omniflake";
  omniflake.inputs.nixpkgs.follows = "nixpkgs";

  flake-parts.url    = "github:hercules-ci/flake-parts";
  wrappers.url       = "github:Lassulus/wrappers";

  stylix.url         = "github:nix-community/stylix/release-26.05";
  stylix.inputs.nixpkgs.follows       = "nixpkgs";

  home-manager.url   = "github:nix-community/home-manager/release-26.05";
  home-manager.inputs.nixpkgs.follows = "nixpkgs";

  sops-nix.url       = "github:Mic92/sops-nix";
  sops-nix.inputs.nixpkgs.follows  = "nixpkgs";

  # nix-index-database.url = "github:nix-community/nix-index-database";
  # nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
  disko.url = "github:nix-community/disko/latest";
  disko.inputs.nixpkgs.follows = "nixpkgs";

  noctalia.url = "github:noctalia-dev/noctalia";
  noctalia.inputs.nixpkgs.follows = "nixpkgs";

  omasnap-nixpkgs.url = "github:yechielw/nixpkgs/c6a32c930a87bc5a6ce8852f4edf6f231cde5ba5";

  };

nixConfig = {
  extra-substituters = [
    "https://nix-community.cachix.org"
    "https://cache.numtide.com"
    "https://noctalia.cachix.org"
    # "https://devenv.cachix.org"
    ];
  extra-trusted-public-keys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
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
    (inputs.omniflake.flakes.import-tree [ ./hosts ./users ./modules ./packages ])
     inputs.home-manager.flakeModules.home-manager
     ];
};}  
# use statix
