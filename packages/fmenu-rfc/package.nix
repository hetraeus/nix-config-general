{ perSystem = { pkgs, ... }: {
  packages.fmenu-rfc = pkgs.writeShellApplication {
    name               = "fmenu-rfc";
    excludeShellChecks = [ "SC2016" ];
    runtimeInputs      = [ pkgs.rsync pkgs.bat pkgs.gawk pkgs.coreutils ];
    text = ''
      RFCs_DIR="$XDG_CACHE_HOME"/RFCs
      [[ -d "$RFCs_DIR" ]] || mkdir "$RFCs_DIR"

      echo "Syncing all RFCs"
      rsync -avz --delete rsync.rfc-editor.org::rfcs-text-only "$RFCs_DIR"
        
      export  FZF_DEFAULT_OPTS="\
        --layout=reverse        \
        --ansi                  \
        --info=inline-right     \
        --no-separator          \
        --scroll-off=5          \
        --gutter=' '            \
        --pointer=' '           \
        "
      awk '/^  *-+$/ {n++} n>=2 {if (/^[[:space:]]*$/) printf "\x0\n"; else print}' "$RFCs_DIR"/rfc-index.txt \
      | fzf --tac --prompt="$0 " \
            --no-sort --read0    \
            --preview-window=top,60%,border-bottom,wrap   \
            --color='gutter:-1,fg+:#ffffff,fg:#bbbbbb' \
            --preview='bat --color always --style=numbers --language=bsh '"$RFCs_DIR"'"/rfc$(printf %d {1}).txt"' \
  --bind 'enter:become:bat --color always --style=numbers --language=bsh '"$RFCs_DIR"'"/rfc$(printf %d {1}).txt"'
    '';
  };
};}
