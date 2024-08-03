{ flake.nixosModules.terminal_gui = { xterm, ... }: {
  # Don't need xterm from Xorg
  services.xserver.excludePackages = [ xterm ];

};

flake.homeModules.terminal_gui = { lib, pkgs, ... }: {
  programs.foot.enable  = true;
  home.packages = [ pkgs.blobdrop ];
  programs.kitty.enable = true;
  programs.kitty.shellIntegration.enableZshIntegration = false; # it's awkward

  home.sessionVariables.TERM =  "kitty";
  programs.kitty.keybindings = {
  # ctrl+t               new_tab_with_cwd
    "alt+space"          = "start_resizing_window";
    "ctrl+shift+q"       = "no_op";
    "ctrl+shift+t"       = "new_tab_with_cwd";
    "ctrl+tab"           = "next_tab";
    "ctrl+shift+tab"     = "previous_tab";
    "ctrl+shift+a"       = "launch --location=hsplit --cwd=current";
    "ctrl+shift+enter"   = "launch --location=vsplit --cwd=current";
    "alt+1"              = "goto_tab 1";
    "alt+2"              = "goto_tab 2";
    "alt+3"              = "goto_tab 3";
    "alt+4"              = "goto_tab 4";
    "alt+5"              = "goto_tab 5";
    "alt+6"              = "goto_tab 6";
    "alt+7"              = "goto_tab 7";
    "alt+8"              = "goto_tab 8";
    "alt+9"              = "goto_tab 9";
    "alt+0"              = "goto_tab 10";
    "alt+tab"            = "next_window";
    "alt+shift+tab"      = "previous_window";
    "ctrl+left"          = "send_text all \\x1b\\x62";
    "ctrl+right"         = "send_text all \\x1b\\x66";

    "alt+F7"             = "layout_action rotate";

    "ctrl+shift+f"       = "launch --stdin-source=@screen_scrollback --type=overlay fzf --no-sort --exact --tac --bind \"enter:execute(xsel --primary <<< {}; notify-send copied! {})\"";
    "ctrl+shift+h "      = "launch --stdin-source=@screen_scrollback --type=overlay nvim '+set buftype=nowrite' '+file kitty buffer' '+nnoremap <ENTER> K' '+nnoremap <BACKSPACE> <C-o>' '+noremap q :quit!<CR>' '+let g:test = substitute($KITTY_PIPE_DATA, \":.*\", \"\", \"\")' \"+execute ':normal G' . g:test . '␙$'\" -";

    "shift+up"           = "move_window           up";
    "shift+left"         = "move_window         left";
    "shift+right"        = "move_window        right";
    "shift+down"         = "move_window         down";

    "ctrl+alt+left"      = "neighboring_window  left";
    "ctrl+alt+right"     = "neighboring_window right";
    "ctrl+alt+up"        = "neighboring_window    up";
    "ctrl+alt+down"      = "neighboring_window  down";

    "ctrl+plus"          = "change_font_size   current +2.0";
    "ctrl+minus"         = "change_font_size   current -2.0";
    };
  programs.kitty.settings =  {
    bold_font             =    "auto";
    italic_font           =    "auto";
    bold_italic_font      =    "auto";
    disable_ligatures     =  "always";
    enabled_layouts       = "splits:split_axis=horizontal,tall:bias=60;full_size=1,fat:bias=65;full_size=1,horizontal,vertical,grid";
    tab_bar_style         = "separator";
    tab_separator         = "\'  │  \'";
    scrollback_lines      = -1;

    # Colors
    # iptraf-ng in color mode is usable with these dark  themes: Dracula, Falcon, Glacier, Hurtado, Neopolitan, Github
    # iptraf-ng in color mode is usable with these light themes: CLRS
    #background           =   #111111
    #background_opacity    =  lib.mkForce "0.90";

    enable_audio_bell         =  "no";
    cursor_stop_blinking_after=     0;
    confirm_os_window_close   =     0;

    # Interactions
    allow_remote_control      =  "yes";
    clipboard_control         =  "write-clipboard write-primary";
    };
  home.shellAliases.lsi = "${lib.getExe' pkgs.kitty "kitten"} icat ";
  xdg.configFile."kitty/open-actions.conf".text = ''
  protocol file
  action launch --cwd=current --type background ${lib.getExe pkgs.blobdrop} ''${FILE_PATH}
  '';

};}
