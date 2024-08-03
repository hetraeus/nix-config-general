{ perSystem = { pkgs, ... }: {
  packages.fmenu-image-convert = pkgs.writeShellApplication {
    name          = "fmenu-image-convert";
    runtimeInputs = [ pkgs.fzf pkgs.coreutils pkgs.imagemagick pkgs.ghostscript ];
    text = ''
      export  FZF_DEFAULT_OPTS="\
      --info=hidden             \
      --layout=reverse          \
      --no-separator            \
      --gutter=' '              \
      --pointer=' '             \
      --prompt='  '             \
      --scroll-off=5
      "
      while ! "''${finished:-false}"; do
      # shellcheck disable=SC1112
      extension="$(fzf --accept-nth 1 --header="$*" <<< \
      "$(magick identify -list format | awk '$2~"^.w.$" { print gensub(/\*/, " ", 1) }')
      ✅ Done")"
      case "''${extension:-"✅ Done"}" in
        *" Done" ) exit;;
        *        )
          extension=''${extension,,}
          for each_image in "$@"; do
            [[ -e "''${each_image%.*}.$extension" ]] && exit
            magick "$each_image" "''${each_image%.*}.$extension"
            done
          read   -rp  "Press enter to continue" ;;
      esac; done
    '';
  };
};}
