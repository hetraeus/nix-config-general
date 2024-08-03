{ flake.homeModules.dev_neovim = { lib, pkgs, config, ... } : {

  home.sessionVariables = {
    MANWIDTH = 78;
    MANPAGER = "nvim +Man! -" ;
    };

  home.packages = [ pkgs.unzip ]; # allow zip browsing

  programs.nvf.settings.vim.viAlias  = true;
  programs.nvf.settings.vim.vimAlias = true;

  xdg.desktopEntries.nvim = {
    name = "Neovim";
    exec = "nvim %F"; # original had quotes around %F which opened a blank buffer
    icon = "nvim";
    terminal = true;
    };

  # https://notashelf.github.io/nvf/options.html
  programs.nvf = {
    enable = true;


  };

  home.file."${config.xdg.userDirs.templates}/bash.sh".text = ''
    #!/usr/bin/env bash

    # set -x
    # set -euxo pipefail
    SCRIPT_NAME="$0"
    echo -e "\e]2;🔺 $SCRIPT_NAME\a\033]2;$SCRIPT_NAME\007$SCRIPT_NAME" # terminal
  '';

};}
