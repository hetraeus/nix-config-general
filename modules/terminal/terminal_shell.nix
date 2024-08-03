{ flake.nixosModules.terminal_shell = { pkgs, self, ... }: {
  environment.systemPackages = [
    # Don't install which, use command -v . zsh has also whence -c or whence -f instead
    pkgs.fzf pkgs.jq pkgs.fd pkgs.dust pkgs.gawk pkgs.gnused
    self.packages.${pkgs.stdenv.hostPlatform.system}.xxx
    ];
  services.rsync.enable = true;

  environment.shellAliases = {
    ":x"     = " exit 0                      ";
    ":X"     = " :x                          ";
    ":q"     = " :x                          ";
    ":Q"     = " :x                          ";
    ".."     = " cd ..                       ";
    df       = "df     --human-readable      ";
    diff     = "diff   --color               ";
    chown    = " chown --preserve-root  --   ";
    chmod    = " chmod --preserve-root  --   ";
    chgrp    = " chgrp --preserve-root  --   ";
    updatedb = "updatedb   --verbose         ";
    };

  environment.pathsToLink = [ "/share/zsh" ]; # get completion for system packages
  programs.zsh = {
    enable      = true;
    setOptions  = [ "aliases" "auto_pushd" "auto_param_slash" "extended_glob" "no_share_history" "hist_ignore_space" "hist_reduce_blanks" "hist_ignore_all_dups" "hist_expire_dups_first" "interactive_comments" "prompt_subst" "noclobber" ];
    enableLsColors        = true;
    enableCompletion      = true;
    enableBashCompletion  = true; # for azure-cli and potentially more

    interactiveShellInit = ''
      bindkey   ''${terminfo[kcuu1]} history-search-forward
      bindkey   ''${terminfo[kcuu1]} history-search-backward
      bindkey   ''${terminfo[kdch1]} delete-char
      bindkey   '5~'                 kill-word
      bindkey   '^H'                 backward-delete-word
      '';

  #  syntaxHighlighting.enable = true;
    };
};

flake.homeModules.terminal_shell = { pkgs, lib, config, self, ... }: {
  home.packages = [
    self.packages.${pkgs.stdenv.hostPlatform.system}.rgii
    self.packages.${pkgs.stdenv.hostPlatform.system}.fdii
    self.packages.${pkgs.stdenv.hostPlatform.system}.fdx
    pkgs.moreutils
    pkgs.file
    pkgs.gawk pkgs.ijq
    pkgs.w3m

    pkgs.mcat
    ];

  programs.fzf.enable         = true;
  programs.fzf.colors.gutter  = "-1";
  programs.fzf.defaultOptions = [
    "--layout=reverse"
    "--no-separator"
    "--info=inline-right"
    "--scroll-off=5"
    "--prompt='  '"
    "--pointer=' '"
    "--gutter=' '"
    ];

  programs.eza.enableZshIntegration = true;
  programs.fzf.enableZshIntegration = true;
  programs.zsh = {

  #NOTE:
  # programs.zsh.enable = true (or the equivalent for other shells) are
  # needed to source ~/.nix-profile/etc/profile.d/hm-session-vars.sh
    enable                        = true;

  #NOTE: Add environment.pathsToLink = [ "/share/zsh" ]; to your
  # system configuration to get completion for system packages
    enableCompletion              = true;

    defaultKeymap                 = "emacs";
    syntaxHighlighting.enable     = true;
    autosuggestion.enable         = false;
    historySubstringSearch.enable = false; # NOTE *substring* search SUCKS!!! Use fzf

    # Order value = 1500 to keep
    #   ZSH_HIGHLIGHT_STYLES[comment]='fg=#777777'
    # at the bottom
    initContent = lib.mkOrder 1500 ''
  autoload -z    edit-command-line
  zle      -N    edit-command-line

  zstyle ':completion::complete:*' use-cache        1
  zstyle ':completion:*:functions' ignored-patterns '_*'
  zstyle ':completion:*'           list-colors      "=(#b) #([0-9]#)*=36=31"
  zstyle ':completion:*:kill:*'    command          'echo; ${lib.getExe' pkgs.procps "ps"} -a --user $USER --format pid,%cpu,tty,cputime,cmd'

  # "delete word" sensible stops. Keep this BEFORE zsh-syntax-highlight
  autoload -U select-word-style && select-word-style bash

  # r builtin repeats last command. I don't like it
  disable r

  # Keys                                                                       {{{

  #INFO: simpler editor to edit the command line with ctrl-x ctrl-e
  zstyle :zle:edit-command-line editor ${lib.getExe pkgs.helix}
  bindkey    '^X^E'               edit-command-line

  #bindkey    '^[[3~'              delete-char
  bindkey    '^[[4~'              end-of-line
  bindkey    '^[OF'               end-of-line
  bindkey    '^[[H'               beginning-of-line
  bindkey    '^[[F'               end-of-line
  bindkey    '^[[1~'              beginning-of-line
  bindkey    '^[[Z'               reverse-menu-complete
  bindkey    '^[e'                forward-word
  bindkey    "''${terminfo[khome]}" beginning-of-line
  bindkey    "''${terminfo[kend]}"  end-of-line

  bindkey   ''${terminfo[kcud1]}  history-search-forward
  bindkey   ''${terminfo[kcuu1]}  history-search-backward

  bindkey    "''${terminfo[kdch1]}" delete-char
  bindkey    '5~'                 kill-word
  bindkey    '^H'                 backward-delete-word

  # }}}
  # cd Undo key                                                                {{{
  cdUndoKey()          {
    popd     > /dev/null || return
    zle      reset-prompt
    echo
  }
  zle -N                 cdUndoKey
  bindkey '^[[1;3D'      cdUndoKey
  # }}}
  # cd Parent key                                                              {{{
  cdParentKey()        {
    pushd .. > /dev/null
    zle      reset-prompt
    echo
  }

  zle -N                 cdParentKey
  bindkey '[1;3A'      cdParentKey
  # }}}

  if [ -z "$DISPLAY" ]; then
  # Unbind useless keys                                                        {{{
  bindkey -r '^[1'
  bindkey -r '^[2'
  bindkey -r '^[3'
  bindkey -r '^[4'
  bindkey -r '^[5'
  bindkey -r '^[6'
  bindkey -r '^[7'
  bindkey -r '^[8'
  bindkey -r '^[9'
  bindkey -r '^[0'
  # }}}
  # Media functions define                                                     {{{
  # ncmpcppShow()        { ncmpcpp --host=$XDG_RUNTIME_DIR/mpd/socket <"$TTY";   zle redisplay  ; }; zle -N ncmpcppShow         ; bindkey '^[d' ncmpcppShow
  # radio_Term()         { radio_term                                    ; }; zle -N radio_Term          ; bindkey '^[p' radio_Term
  toggleMusicDaemon()  { mpc --host=$XDG_RUNTIME_DIR/mpd/socket --quiet toggle 2> /dev/null   ; }; zle -N toggleMusicDaemon   ; bindkey '^[z' toggleMusicDaemon
  nextSongMusicDaemon(){ mpc --host=$XDG_RUNTIME_DIR/mpd/socket --quiet next   2> /dev/null   ; }; zle -N nextSongMusicDaemon ; bindkey '^[<' nextSongMusicDaemon
  prevSongMusicDaemon(){ mpc --host=$XDG_RUNTIME_DIR/mpd/socket --quiet prev   2> /dev/null   ; }; zle -N prevSongMusicDaemon ; bindkey '^[>' prevSongMusicDaemon
  toggleVolumeMixer()  { wpctl set-mute    @DEFAULT_AUDIO_SINK@ toggle ; }; zle -N toggleVolumeMixer   ; bindkey '^[m' toggleVolumeMixer
  decreaseVolumeMixer(){ wpctl set-volume  @DEFAULT_AUDIO_SINK@ 6%-    ; }; zle -N decreaseVolumeMixer ; bindkey '^[a' decreaseVolumeMixer
  increaseVolumeMixer(){ wpctl set-volume  @DEFAULT_AUDIO_SINK@ 6%+    ; }; zle -N increaseVolumeMixer ; bindkey '^[s' increaseVolumeMixer
  # }}}
  fi

  ZSH_HIGHLIGHT_STYLES[comment]='fg=#777777'

  sub-shell() {
    BUFFER="($BUFFER)"
    CURSOR=$#BUFFER
    }
  zle -N sub-shell
  bindkey '^B^S' sub-shell

  # formatting as made by `declare -f k`
  k () {
  	LABEL_NEW="🟢 new project"
  	LABEL_GIT=" ⎇ new git project"
    PROJDIR_PARENT="${config.xdg.userDirs.documents}"
  	cd "$PROJDIR_PARENT" || return
  	PROJDIR="$( {
        fd --follow --max-depth=1 --type directory .
        printf "%s\n%s" "$LABEL_NEW" "$LABEL_GIT"
        } | fzf --height=10 --exact --sync --gutter=' ' --query="''${*:-}")"
  	case "$PROJDIR" in
  		("$LABEL_NEW") vared -p "$(date --iso-8601=minutes) : $LABEL_NEW name: " -c NEWPROJ
  			mkdir "$PROJDIR_PARENT/$NEWPROJ"
  			cd "$PROJDIR_PARENT/$NEWPROJ" || return ;;
  		("$LABEL_GIT") vared -p "$(date --iso-8601=minutes) : $LABEL_GIT name: " -c NEWPROJ
  			mkdir "$PROJDIR_PARENT/$NEWPROJ"
  			cd "$PROJDIR_PARENT/$NEWPROJ" || return
  			git init ;;
  		("") return ;;
  		(*) [[ -d "$PROJDIR" ]] && {
  				cd "$PROJDIR"
  				return
  			}
  			echo
  			cat {README,TODO}{,.txt,.asciidoc,.md,.rst} 2> /dev/null
  			echo ;;
  	esac
  }
      '';};

  #programs.zoxide.enable = true;
  programs.eza.enable = true;
  programs.eza.extraOptions = [
    "--long"
    "--header"
    "--git"
    "--almost-all"
    "--group"
    "--hyperlink"
    "--group-directories-first"
    ];
  home.shellAliases = {
    l  = "eza";
    sl = "eza";
    };

  home.sessionVariables.MANPAGER = lib.mkOverride 2000 "less";
  home.sessionVariables.VISUAL   = lib.mkOverride 2000 "less";

  home.shellAliases = {
    less    =      "${config.home.sessionVariables.MANPAGER}";
    ll      =      "${config.home.sessionVariables.MANPAGER}";
    vs      = "run0 ${config.home.sessionVariables.VISUAL} -u NORC" ;
    Sw      = "run0 ${config.home.sessionVariables.VISUAL} -u NORC" ;
    ":Sw"   = "run0 ${config.home.sessionVariables.VISUAL} -u NORC" ;
    };
  programs.zsh.history = {
    share         = false;
    extended      = true;
    size          = 10000;
    ignoreAllDups = true;
    ignoreSpace   = true;
    };

  programs.zsh.history.ignorePatterns = [
  "?" "??"
  ">\|"
  "buku * -d *" "buku *--delete *"
  "find * rm *" "find * -exec*" "find * -delete*"
  "git branch -D *" "git branch -d *" "git branch --delete *"
  "gpg *--delete*-key*"
  "halt" "halt *"
  "kill *" "pkill *" "killall *"
  "reboot" "reboot *"
  "rm *" "\\rm *" "gio remove *"
  "find * shred *" "shred *"
  "systemctl poweroff"                "systemctl poweroff *"
  "systemctl reboot"                  "systemctl reboot *"
  "systemctl soft-reboot"             "systemctl soft-reboot *"
  "systemctl kexec"                   "systemctl kexec *"
  "systemctl rescue"                  "systemctl rescue *"
  "systemctl emergency"               "systemctl emergency *"
  "systemctl halt"                    "systemctl halt *"
  "systemctl sleep"                   "systemctl sleep *"
  "systemctl hybrid-sleep"            "systemctl hybrid-sleep *"
  "systemctl hibernate"               "systemctl hibernate *"
  "systemctl suspend"                 "systemctl suspend *"
  "systemctl suspend-then-hibernate"  "systemctl suspend-then-hibernate *"
  ];

  programs     = {
    fd.enable  = true;
    bat.enable = true;
    jq.enable  = true;
    };
  programs.ripgrep = {
    enable     = true;
    arguments  = [ "--smart-case" ];
    };

  programs.starship.enable      = true;
  programs.starship.settings    = {
    sudo.disabled               = true;
    time.disabled               = false;
    directory.truncate_to_repo  = false;
    directory.truncation_length = -1;
    };

  home.shellAliases.ii = "${lib.getExe' pkgs.xdg-utils "xdg-open"}";

};}
