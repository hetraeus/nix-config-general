{ flake.nixosModules.geography = { ... }: {

};

flake.homeModules.geography = { pkgs, ... }: {

  home.packages = [
    pkgs.kdePackages.marble
    ];
   };
}
