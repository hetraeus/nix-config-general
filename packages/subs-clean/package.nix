{ perSystem = { pkgs, ... }: {
  packages.subs-clean = let
    pattern_file = ./list ;
  in pkgs.writeShellApplication {
    name          = "subs-clean";
    runtimeInputs = [ pkgs.gawk ];
    text = ''
      gawk --include inplace '
        BEGIN {
          IGNORECASE = 1;
          while ((getline pat < "${pattern_file}") > 0) {
            if (pat != "") patterns = patterns (patterns ? "|" : "") pat;
            }
          close("${pattern_file}");
          if (patterns == "") exit;
          }
        { gsub(patterns, ""); print; } ' "$@"
    '';
  };
};}
