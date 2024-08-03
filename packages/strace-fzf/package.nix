{ perSystem = { pkgs, ... }: {
  packages.strace-fzf = pkgs.writeShellApplication {
    name = "strace-fzf";
    runtimeInputs = [ pkgs.fzf pkgs.strace ];
    text = ''
      strace "$@" 2>&1         \
      | fzf                    \
      --ansi                   \
      --raw --gutter-raw=' '   \
      --color='fg:#969696,bg+:#04727d,fg+:#fac6c1,hl+:#d7005f,hl:#d7005f,query:#d7005f,info:#757676,gutter:-1' \
      --exact --track --no-sort
    '';
  };
};}
