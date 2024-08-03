{ perSystem = { pkgs, ... }: {
  packages.fmenu-games-roms = pkgs.writeShellApplication {
    name          = "fmenu-games-roms";
    text          = builtins.readFile ./fmenu-games-roms;
    runtimeInputs = [
      pkgs.fzf pkgs.fd
      pkgs.fuse-emulator pkgs.sameboy pkgs.zsnes2 # ruffle
    ];
  };
};}
