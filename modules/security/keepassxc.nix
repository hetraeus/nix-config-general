{ flake.homeModules.keepassxc = { pkgs, ... }: {
  programs.keepassxc.enable = true;
  # BUG: https://github.com/nix-community/home-manager/pull/7675/files
  programs.keepassxc.settings.Browser.UpdateBinaryPath = false;

  wayland.windowManager.hyprland.settings.window_rule = [{
    match.class = "^(org.keepassxc.KeePassXC)$";
    no_screen_share = true;
    }];

};}

