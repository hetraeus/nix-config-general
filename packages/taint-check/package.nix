{ perSystem = { pkgs, ... }: {
  packages.taint-check = pkgs.writeShellApplication {
    name = "taint-check";
    text = builtins.readFile ./taint-check;
    runtimeInputs = [ pkgs.gnugrep ];
  };
};}
