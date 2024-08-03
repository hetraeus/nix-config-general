{ perSystem = { pkgs, ... }: {
  packages.fdii = pkgs.writeShellApplication {
    name          = "fdii";
    runtimeInputs = [ pkgs.xdg-utils pkgs.fd pkgs.bat pkgs.fzf pkgs.helix ];
    text = ''
      (( $# == 0 )) && exit
      mapfile -t MATCHING_FILES < <(fd --type=f --full-path -- "''${@// /*}" . )
      [[ ''${#MATCHING_FILES[@]} -eq 0 ]] && exit;
      [[ ''${#MATCHING_FILES[@]} -eq 1 ]] && {
        hx          "''${MATCHING_FILES[0]}"
        printf "%s" "''${MATCHING_FILES[0]}"
        exit
        }
      printf "%s\n" "''${MATCHING_FILES[@]}"

      CHOICE="$(printf '%s\n' "''${MATCHING_FILES[@]}" \
      | fzf                                \
      --query="$*"                         \
      --header="Find files"                \
      --preview-window=border-left         \
      --prompt="       "                   \
      --preview-window="60%"               \
      --bind='enter:become:xdg-open {}'    \
      --preview='bat --style=plain --color=always --pager "less -p {}" {}' \
      -- )"
      echo "''${CHOICE:-}"
    '';
  };
};}
