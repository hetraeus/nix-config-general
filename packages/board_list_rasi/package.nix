{ perSystem = { pkgs, ... }: {
  packages.board_list_rasi = pkgs.writeTextFile {
    name = "board_list.rasi"; # Keeps the proper extension
    text = builtins.readFile ./board_list.rasi ;
    executable = false; # Set to true only if the reading program requires it
  };
};}
