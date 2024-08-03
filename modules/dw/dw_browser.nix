{ flake.homeModules.dw_browser = { ... }: {
  programs.firefox.policies.ExtensionSettings."cliget@zaidabdulla.com" = {
    install_url = "https://addons.mozilla.org/firefox/downloads/latest/cliget/latest.xpi";
    installation_mode = "force_installed";
    };

  programs.firefox.policies = {
    # about:policies#documentation
    PromptForDownloadLocation = true;
    DefaultDownloadDirectory  = true;
    };

};}
