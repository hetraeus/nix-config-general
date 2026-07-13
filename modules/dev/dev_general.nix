{ flake.nixosModules.dev_general = { config, ... }: {

  services.opensnitch.rules.src_git_gravatar = {
    name      = "src_git_gravatar";
    enabled   = true;
    created   = "2011-01-01T10:00:00.000000000+00:00"; # silence logs
    action    = "allow";
    duration  = "always";
    operator  = {
      type    = "list";
      operand = "list";
      list    = [{
      type    = "regexp";
      operand = "process.path";
      data    = "^(/nix/store/[a-z0-9]{32}-sourcegit-.*/lib/sourcegit/SourceGit)$";
      } {
      type    = "simple";
      operand = "dest.port";
      data    = "443";
      } {
      type    = "simple";
      operand = "dest.host";
      data    = "www.gravatar.com";
      } {
      type    = "regexp";
      operand = "user.id";
      data    = "^(${toString config.users_list.principalUserUid})$";
      }];
  };};

  services.opensnitch.rules.zed_api_dev = {
    name      = "zed_api_dev";
    enabled   = true;
    created   = "2011-01-01T10:00:00.000000000+00:00"; # silence logs
    action    = "allow";
    duration  = "always";
    operator  = {
      type    = "list";
      operand = "list";
      list    = [{
      type    = "simple";
      operand = "dest.port";
      data    = "443";
      } {
      type    = "regexp";
      operand = "dest.host";
      data    = "^(cdn\.agentclientprotocol\.com|api\.zed\.dev)$";
      }];
  };};

  services.opensnitch.rules.zed_local = {
    name      = "zed_local";
    enabled   = true;
    created   = "2011-01-01T10:00:00.000000000+00:00"; # silence logs
    action    = "allow";
    duration  = "always";
    operator  = {
      type    = "list";
      operand = "list";
      list    = [{
      type    = "regexp";
      operand = "process.path";
      data    = "^(/nix/store/[a-z0-9]{32}-zed-editor-.*/libexec/\.zed-editor-wrapped)$";
      } {
      type    = "regexp";
      operand = "dest.ip";
      data    = "^(127\\.0\\.0\\.1|::1)$";
      }];
  };};

  services.opensnitch.rules.zed_extensions = {
    name      = "zed_extensions";
    enabled   = true;
    created   = "2011-01-01T10:00:00.000000000+00:00"; # silence logs
    action    = "allow";
    duration  = "always";
    operator  = {
      type    = "list";
      operand = "list";
      list    = [{
      type    = "regexp";
      operand = "process.path";
      data    = "^(/nix/store/[a-z0-9]{32}-zed-editor-.*/libexec/\.zed-editor-wrapped)$";
      } {
      type    = "simple";
      operand = "dest.port";
      data    = "443";
      } {
      type    = "regexp";
      operand = "dest.host";
      data    = "^(api\.githubcopilot\.com|zed-extensions\.nyc3\.digitaloceanspaces\.com|avatars\.githubusercontent\.com)$";
      } {
      type    = "regexp";
      operand = "user.id";
      data    = "^(${toString config.users_list.principalUserUid})$";
      }];
  };};

  services.opensnitch.rules.llm_ollama = {
    name      = "llm_ollama";
    enabled   = true;
    created   = "2011-01-01T10:00:00.000000000+00:00"; # silence logs
    action    = "allow";
    duration  = "always";
    operator  = {
      type    = "list";
      operand = "list";
      list    = [{
      type    = "regexp";
      operand = "process.path";
      data    = "^(/nix/store/[a-z0-9]{32}-ollama-.*/bin/ollama)$";
      } {
      type    = "simple";
      operand = "dest.port";
      data    = "443";
      } {
      type    = "regexp";
      operand = "dest.host";
      data    = "^(ollama\.com)$";
      } {
      type    = "regexp";
      operand = "user.id";
      data    = "^(${toString config.users_list.principalUserUid})$";
      }];
  };};

  services.opensnitch.rules.ai_antigravity = {
    name      = "ai_antigravity";
    enabled   = true;
    created   = "2011-01-01T10:00:00.000000000+00:00"; # silence logs
    action    = "allow";
    duration  = "always";
    operator  = {
      type    = "list";
      operand = "list";
      list    = [{
      type    = "regexp";
      operand = "process.path";
      data    = "^(/nix/store/[a-z0-9]{32}-antigravity-.*/lib/antigravity/(antigravity|resources/app/extensions/antigravity/bin/language_server_linux_x64))$";
      } {
      type    = "simple";
      operand = "dest.port";
      data    = "443";
      } {
      type    = "regexp";
      operand = "dest.host";
      data    = "^((mobile|browser)\.events\.data\.microsoft\.com|(cloudcode-pa|daily-cloudcode-pa|oauth2|play|fonts|www)\.googleapis\.com|fonts\.gstatic\.com|lh3\.googleusercontent\.com|main\.vscode-cdn\.net|default\.exp-tas\.com|open-vsx\.org|antigravity-unleash\.goog)$";
      } {
      type    = "regexp";
      operand = "user.id";
      data    = "^(${toString config.users_list.principalUserUid})$";
      }];
  };};

  services.opensnitch.rules.ai_mistral = {
    name      = "ai_mistral";
    enabled   = true;
    created   = "2011-01-01T10:00:00.000000000+00:00"; # silence logs
    action    = "allow";
    duration  = "always";
    operator  = {
      type    = "list";
      operand = "list";
      list    = [{
      type    = "regexp";
      operand = "process.path";
      data    = "^(/nix/store/[a-z0-9]{32}-python3-.*/bin/python3\..*)$";
      } {
      type    = "simple";
      operand = "dest.port";
      data    = "443";
      } {
      type    = "regexp";
      operand = "dest.host";
      data    = "^(console|api)\.mistral\.ai|experiments\.mistral\.services)$";
      } {
      type    = "regexp";
      operand = "user.id";
      data    = "^(${toString config.users_list.principalUserUid})$";
      } {
      type    = "regexp";
      operand = "process.command";
      data    = "^(/etc/profiles/per-user/.*/bin/vibe(| .*))$";
      }];
  };};

  services.opensnitch.rules.nix-init = {
    name      = "nix-init";
    enabled   = true;
    created   = "2011-01-01T10:00:00.000000000+02:00"; # silence logs
    action    = "allow";
    duration  = "always";
    operator  = {
      type    = "list";
      operand = "list";
      list    = [{
      type    = "regexp";
      operand = "process.path";
      data    = "^(/nix/store/[a-z0-9]{32}-nix-init-.*/bin/nix-init)$";
      } {
      type    = "simple";
      operand = "dest.port";
      data    = "443";
      } {
      type    = "regexp";
      operand = "dest.host";
      data    = "^((static|index)\.crates\.io)$";
      }];
  };};
};


flake.homeModules.dev_general = { lib, pkgs, config, ... } :
let

fmenu-mistral = pkgs.writeShellApplication {
  runtimeInputs = [ pkgs.curl pkgs.jq pkgs.bat ];
  name = "fmenu-mistral";
  text = ''
    curl \
    --location https://api.mistral.ai/v1/chat/completions    \
    --header 'Content-Type: application/json'                \
    --header 'Accept: application/json'                      \
    --header "Authorization: Bearer $(<"$MISTRAL_API_PATH")" \
    --data '{ "model": "mistral-large-latest", "messages":
    [{ "role": "user", "content": "'"$(printf '%s\n' "$*")"'" }]}' \
    | jq --raw-output '.choices[0].message.content' \
    | bat --language=markdown --paging=never --plain
  '';};

in
{

  programs.zed-editor    = {
    enable               = true;
    installRemoteServer  = true;
    userSettings = {
      helix_mode  = true;
      auto_indent = false;
      tab_size    = 2;
      relative_line_numbers = "enabled";
      soft_wrap   = "editor_width";
      };
    userKeymaps = [ {
      context = "Editor";
      bindings = { "alt-x" = "command_palette::Toggle"; };
      } {
      context = "vim_mode == helix_normal || vim_mode == normal || vim_mode == visual";
      bindings = { backspace = "vim::DeleteLeft"; };
      } {
      context = "vim_mode == helix_normal || vim_mode == normal || vim_mode == visual";
      bindings = { delete = "vim::DeleteRight"; };
      } {
      context = "vim_mode == helix_normal";
      bindings = { "shift-x" = [ "editor::SelectUpByLines" { "lines" = 1;} ]; };
      } ];
     userTasks = [ {
       #INFO: https://zed.dev/docs/tasks
       label = "Format Code";
       command = "nix";
       args = [ "fmt" "$ZED_WORKTREE_ROOT" ];
       }];

    userSettings.languages.Nix.language_servers = [ "nixd" "!nil" ];
    extraPackages = [ pkgs.basedpyright pkgs.nixd pkgs.python3Packages.python-lsp-server pkgs.kotlin-language-server ];
    extensions = [
      "assembly" # useful for mindustry scripts too!
      "ansible"
      "asciidoc"
      "awk"
      "basher"
      "comment"
      "ini"
      "kotlin"
      "json5"
      "lua"
      "nix"
      "pylsp"
      "rst"
      "sql"
      "vale"
      "verilog"
      ];
  };

xdg.mimeApps.defaultApplications = let
  default_viewer = "dev.zed.Zed.desktop";
  viewerMimeTypes = [
    "application/javascript"
    "application/json"
    "application/x-java"
    "application/x-subrip"
    "application/yaml"
    "text/plain"
    "text/vtt"
    "text/x-script.python"
    "text/x-shellscript"
    ];
  in lib.genAttrs viewerMimeTypes (_: [ default_viewer ]);



  home.packages = [
    pkgs.devenv
    fmenu-mistral
    pkgs.git # https://discourse.nixos.org/t/cannot-login-with-gh-cli/16601
    pkgs.git-lfs
    pkgs.sourcegit
    # pkgs.beekeeper-studio # BUG: https://github.com/beekeeper-studio/beekeeper-studio/pull/3023 meanwhile use flatpak

    ];
  programs.git.enable = true; #lib.mkForce false; # https://discourse.nixos.org/t/cannot-login-with-gh-cli/16601
  programs.git.signing.format = "openpgp";

  programs.mistral-vibe.enable = true;
  # programs.mistral-vibe.package = pkgs.mistral-vibe ;
  programs.gh.enable      = true;
  programs.lazygit.enable = true;
  services.ollama.enable  = true;
  programs.jjui.enable    = true;
  programs.fresh-editor.enable = true;
  programs.nix-init.enable     = true;

  # INFO: https://editorconfig.org/
  editorconfig.enable        = true;
  editorconfig.settings."*"  = {
    charset                  = "utf-8";
    end_of_line              = "lf";
    indent_style             = "space";
    indent_size              = 2;
  #   insert_final_newline     = true;

    # INFO: autotrim pollutes git commits, disable it
    # https://web.git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=7da9dfdd5a3dbfd3d2450d9c6a3d1d699d625c43
    # also, it may break scripts requiring spaces at the end
    trim_trailing_whitespace = false;
    };

  home.shellAliases.nh-dev   = "nix develop --offline --no-update-lock-file";
  home.sessionVariables.MISTRAL_API_PATH="${config.sops.secrets."ai-api-mistral".path}";

  home.shellAliases.antigrav = "env GEMINI_API_KEY=\"$(cat ${config.sops.secrets."ai-api-antigravity".path})\" ${lib.getExe config.programs.antigravity-cli.package} ";
  programs.antigravity-cli.enable = true;
  programs.antigravity-cli.package = pkgs.antigravity; # TODO delete me
  programs.antigravity-cli.commands.sciency.description = "sciency";
  programs.antigravity-cli.commands.sciency.prompt = "Write me the factually correct, most accurate and scientifically sound explanation of {{args}}";
  programs.antigravity-cli.commands.eli5.description = "eli5";
  programs.antigravity-cli.commands.eli5.prompt = "Write me the factually correct, most accurate and scientifically sound explanation of this argument in simple terms: {{args}}";
  };

}
