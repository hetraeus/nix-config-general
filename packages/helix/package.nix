{ inputs, ... }: {
  perSystem = { lib, pkgs, ... }: {

    packages.helix = (inputs.wrappers.wrapperModules.helix.apply {
      inherit pkgs;
      extraPackages = with pkgs; [
        bash-language-server shellcheck gopls nil
        python3Packages.python-lsp-server
        lldb delve taplo terraform-ls lua-language-server
        vscode-langservers-extracted # html css
        markdown-oxide jq-lsp glsl_analyzer
        rustup
        yaml-language-server
        wl-clipboard-rs
        ];

      settings.keys = {
        insert          = {
          F2            = "rename_symbol";
          "del"         = "delete_selection";
          "backspace"   = "delete_char_backward";
          "A-x"         = "command_palette";
          };

        normal          = {
          F2            = "rename_symbol";
          "ins"         = "insert_mode";
          "del"         = [ "yank" "yank_to_primary_clipboard" "yank_to_clipboard" "delete_selection" ];
          "d"           = [ "yank" "yank_to_primary_clipboard" "yank_to_clipboard" "delete_selection" ];
          "backspace"   = "delete_char_backward";
          "y"           = [ "yank" "yank_to_primary_clipboard" "yank_to_clipboard" ];
          " "."y"       = [ "yank" "yank_to_primary_clipboard" "yank_to_clipboard" ];
          "A-x"         = "command_palette";
          "A-backspace" = "delete_word_backward";
          "A-del"       = "delete_word_forward";
          "X"           = "extend_line_above";
          };

        select          = {
          F2            = "rename_symbol";
          "ins"         = "insert_mode";
          "del"         = "delete_selection";
          "backspace"   = "delete_char_backward";
          "y"           = [ "yank" "yank_to_primary_clipboard" "yank_to_clipboard" ];
          " "."y"       = [ "yank" "yank_to_primary_clipboard" "yank_to_clipboard" ];
          "A-x"         = "command_palette";
          };
        };

      settings.editor = {
        statusline.mode.normal    = "NORMAL";
        statusline.mode.insert    = "INSERT";
        statusline.mode.select    = "SELECT";
        line-number               = "relative";
        soft-wrap.wrap-indicator  = "";
        soft-wrap.enable          = true;
        lsp.display-messages      = true;
        color-modes               = true;
        cursorline                = true;
        cursorcolumn              = true;
        cursor-shape.insert       = "bar";
        completion-trigger-len    = 1;
        end-of-line-diagnostics   = "hint";
      # inline-diagnostics.cursor-line =   "error";
      # inline-diagnostics.other-lines = "disable";
        whitespace   = { render   =  "all";
          characters = {
          space      = " ";
          nbsp       = "⍽";
          nnbsp      = "␣";
          tab        = "→";
          newline    = "·";
          tabpad     = "→";
          };};
        };

      languages.language = [{
        name       = "json";
        formatter  = { command = "prettier"; args = ["--parser" "json"]; };
        } {
        name       = "css";
        file-types = ["css"];
        formatter  = { command = "prettier"; args = ["--parser" "css"]; };
        } {
        name       = "javascript";
        file-types = ["js" "jsx" "ts" "tsx"];
        formatter  = { command = "prettier"; args = ["--parser" "typescript"]; };
        } {
        name       = "toml";
        file-types = [ ".editorconfig" "toml" ];
      # } {
      # name = "python";
      # file-types = ["py"];
      # formatter = { command = "black"; args = ["--stdio"]; };
      # } {
      # name = "gleam";
      # formatter = { command = "gleam"; args = ["format" "--stdin"]; };
        }];


    }).wrapper;
  };
}
