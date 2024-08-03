{ perSystem = { pkgs, ... }: {
  packages.fmenu-checksums = pkgs.writeShellApplication {
    name          = "fmenu-checksums";
    runtimeInputs = [ pkgs.fzf pkgs.coreutils ];
    text = ''
      export  FZF_DEFAULT_OPTS="\
      --info=hidden             \
      --layout=reverse          \
      --no-separator            \
      --pointer=' '             \
      --prompt='  '             \
      --gutter=' '              \
      --scroll-off=5
      #--color='bg+:#04727d,fg+:#fac6c1,hl+:#ff497c,gutter:-1,fg:#bbbbbb'"
      while ! "''${finished:-false}"; do
      # shellcheck disable=SC1112
      operation="$(fzf --header="$(printf '%s\n' "$*")" <<< \
      "$(cksum --algorithm "just list them" 2>&1 | awk 'BEGIN{ FS = "[‘’]"} $1~" - " { print "🤖 "$2}')
      ✅ Done")"
      case "''${operation:-"✅ Done"}" in
        *" Done" ) finished=true;;
        "🤖 "*   ) cksum --algorithm="''${operation#* }" -- "$@"
                  read   -rp  "Press enter to continue" ;;
      esac; done
    '';
  };
};}
