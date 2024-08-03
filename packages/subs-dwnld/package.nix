{ perSystem = { pkgs, lib, self', ... }: {

  packages.subs-dwnld = pkgs.writeShellApplication {
    runtimeInputs = [
      pkgs.python3Packages.subliminal
      self'.packages.subs-clean
      ];
    name = "subs-dwnld";
#    excludeShellChecks = [ "SC2068" ];
    text = ''
      set -x
      [[ -z "$1" || -z "$2" || -z "$3" ]] && { printf "usage: destination_directory movie_lookup language_1 language_2 language_etc" ; }
      mkdir --parents "$1"; cd "$1" || exit

      flags=()
      for lang in "''${@:3}"; do flags+=("--language" "$lang"); done
      
      mapfile -t saved_files < <(subliminal --debug download "''${flags[@]}" "$2" 2>&1 \
                                 | sed -n "/^INFO.*Saving/ s/.*'\([^']*\)'$/\1/p" )

      [[ ''${#saved_files[@]} -ge 1 ]] && subs-clean "''${saved_files[@]}"
      '';};
};}
