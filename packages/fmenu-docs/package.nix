{ perSystem = { pkgs, ... }: {
  packages.fmenu-docs = pkgs.writeShellApplication {
    name               = "fmenu-docs";
    excludeShellChecks = [ "SC1091" ];
    runtimeInputs      = [ pkgs.fzf pkgs.xdg-utils ];
    text = ''
      source "$XDG_CONFIG_HOME"/user-dirs.dirs
      DOCS="$XDG_DOCUMENTS_DIR/Documents"
      mkdir "$DOCS" 2>/dev/null || true
      cd    "$DOCS"             || exit
      CHOICE="$(fzf         \
        --multi             \
        --prompt="  "       \
        --pointer=" "       \
        --scroll-off=5      \
        --no-separator      \
        --header-first      \
        --gutter=' '        \
        --layout=reverse    \
        --info=inline-right \
        --header="$DOCS
       $0")"
      [[ -n "$CHOICE" ]] && xdg-open "$CHOICE"
    '';
  };
};}
