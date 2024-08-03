{ perSystem = { pkgs, self', ... }: {
  packages.sbuku = pkgs.writeShellApplication {
    name          = "sbuku";
    text = ''
      export BOARD_LIST_RASI="${self'.packages.board_list_rasi}"
      '' + builtins.readFile ./sbuku_script;
    runtimeInputs = [
      pkgs.coreutils pkgs.jq pkgs.moreutils pkgs.rofi pkgs.gawk pkgs.gnused pkgs.wl-clipboard-rs # needed
      pkgs.xdg-utils # hardcoded
      self'.packages.board_list_rasi
    ];
  };
};}
