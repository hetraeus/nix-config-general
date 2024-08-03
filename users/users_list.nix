{ flake.nixosModules.generalPurpUsers = { lib, inputs, self', self,... }: {

options.users_list = {
  # Define a new option for the principal username
  principalUser = lib.mkOption {
    type = lib.types.str;
    default = "sfx";
    description = "The username of the primary, non-root system user.";
    };
  principalUserUid = lib.mkOption {
    type = lib.types.int;
    default = 1000;
    description = "The pid of the primary, non-root system user.";
  };};

imports = [
  inputs.home-manager.nixosModules.home-manager
  ];

config = {
  home-manager.sharedModules = [ # always on for every user
    { programs.home-manager.enable = true; }
    ];

  home-manager    = {
    backupFileExtension = "backup";
    useGlobalPkgs       = true;
    useUserPackages     = true;
    extraSpecialArgs    = { inherit self' self; };
    };
};};}
