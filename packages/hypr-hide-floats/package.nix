{ perSystem = { pkgs, ... }: {
  packages.hypr-hide-floats = pkgs.writeTextFile {
    name = "toggle-float-special.lua"; # Keeps the proper extension
    text = builtins.readFile ./toggle-float-special.lua;
    executable = false; # Set to true only if the reading program requires it
  };
};}
