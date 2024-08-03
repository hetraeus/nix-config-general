{ flake.nixosModules.generalPurpUsers = { config, inputs, self, ... }: {

  home-manager.users.${config.users_list.principalUser}.imports = [
    inputs.stylix.homeModules.stylix
    inputs.sops-nix.homeManagerModules.sops
    inputs.nvf.homeManagerModules.nvf
    inputs.nix-index-database.homeModules.default

    self.homeModules."${config.users_list.principalUser}Modules"
    self.homeModules.sound_control
    self.homeModules.media_mpd
    self.homeModules.media_editor
    self.homeModules.media_mpv
    self.homeModules.media_dashboard
    self.homeModules.share_local
    self.homeModules.secrets
    self.homeModules.style

    self.homeModules.dev_general
    self.homeModules.dev_helix
    self.homeModules.dev_neovim
    self.homeModules.dev_web
    self.homeModules.desktop_accessibility
    self.homeModules.desktop_display
    self.homeModules.desktop_emoji
    self.homeModules.desktop_hyprland
    self.homeModules.desktop_lock
    self.homeModules.desktop_notification
    self.homeModules.desktop_screenshot
    self.homeModules.desktop_shell
    self.homeModules.desktop_waybar
    self.homeModules.desktop_voice_ryan

    self.homeModules.terminal_fidgets
    self.homeModules.terminal_gui
    self.homeModules.terminal_ms
    self.homeModules.terminal_shell

    self.homeModules.network_pan
    self.homeModules.network_webbrowser
    self.homeModules.network_connect_default

    self.homeModules.virtualisation_containers
    self.homeModules.security
    self.homeModules.media_songrec
    self.homeModules.discord
    self.homeModules.documentation
    self.homeModules.maker
    self.homeModules.pim
    self.homeModules.gaming
    self.homeModules.office
    self.homeModules.backup
    self.homeModules.i18n_en_de_it
    self.homeModules.desktop_qimgv
    self.homeModules.dw_aria
    self.homeModules.dw_browser
    self.homeModules.dw_yt_dlp
    self.homeModules.file_manager
    self.homeModules.mandatory
    self.homeModules.network_osi_level0
    self.homeModules.nix_aliases
    self.homeModules.observability
    self.homeModules.observability_dashboard
    ];
  # User permissions
  users.users."${config.users_list.principalUser}"  = {
  # group        = config.users_list.principalUser;
    shell        = inputs.nixpkgs.legacyPackages."${config.nixpkgs.hostPlatform.system}".zsh;
    isNormalUser = true;
    uid          = config.users_list.principalUserUid;
    extraGroups  = [ # user can:
      "wheel"        # use sudo to escalate privileges
      "wireshark"    # use dumpcap / wireshark to examine network packets
      "samba"        # create samba/CIFS usershares
      "libvirtd"     # libvirt virtual machines without password request
    ];};

  nix.settings.trusted-users = [ config.users_list.principalUser ]; # needed to let devenv manage its cache
  };

flake.homeModules.sfxModules = { osConfig, config, pkgs, lib, ...} : let
  default_browser = "firefox.desktop";
in {

  home.packages = [
    pkgs.celestia
    pkgs.minicom
    pkgs.wayscriber
  #binsider
    ];

  sops.age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
  programs.keepassxc.enable = true;
  # BUG: https://github.com/nix-community/home-manager/pull/7675/files
  programs.keepassxc.settings.Browser.UpdateBinaryPath = false;
  home.file.".gnupg" = { source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.dataHome}/../config/.gnupg"; };

  home.stateVersion  =               "24.11";

# TODO delete this block
gtk.gtk4.theme = lib.mkDefault null;
xdg.userDirs.setSessionVariables = lib.mkDefault false;
wayland.windowManager.hyprland.configType = "lua";
programs.firefox.configPath = "${config.xdg.configHome}/mozilla/firefox";
programs.zsh.dotDir = "${config.xdg.configHome}/zsh";
# end block


  home.username      =       "${osConfig.users_list.principalUser}";
  home.homeDirectory = "/home/${osConfig.users_list.principalUser}";
  xdg.enable                          = true;
  xdg.userDirs.enable                 = true;
  xdg.userDirs.createDirectories      = true;
  home.preferXdgDirectories = lib.mkForce false; # It's easier to use a subdirectory as home

  home.sessionVariables.VISUAL  = "zeditor" ;
  home.sessionVariables.PAGER   = let
    custom_pager = pkgs.writeShellApplication {
    name = "custom_pager";
    text = "nvim +Man!";
    runtimeInputs = [ pkgs.neovim ];
    };
  in "${lib.getExe custom_pager}" ;

  xdg.userDirs.publicShare = "${config.home.homeDirectory}/my/share"; # samba and what else??
  xdg.userDirs.desktop     = "${config.home.homeDirectory}/my/proj";
  xdg.userDirs.download    = "${config.home.homeDirectory}/my/dwnld";
  xdg.userDirs.music       = "${config.home.homeDirectory}/my/music";
  xdg.userDirs.videos      = "${config.home.homeDirectory}/my/movies";
  xdg.userDirs.pictures    = "${config.home.homeDirectory}/my/pics";
  xdg.userDirs.documents   = "${config.home.homeDirectory}/my/proj";
  xdg.userDirs.projects    = "${config.home.homeDirectory}/my/proj";

  programs.firefox.enable      = true;
  programs.firefox.package     = lib.mkForce pkgs.firefox; # avoiding firefox esr because of extensions

  xdg.mimeApps.defaultApplications = {
    "default-web-browser"          = [ "${default_browser}" ];
    "text/html"                    = [ "${default_browser}" ];
    "x-scheme-handler/http"        = [ "${default_browser}" ];
    "x-scheme-handler/https"       = [ "${default_browser}" ];
    "x-scheme-handler/about"       = [ "${default_browser}" ];
    "x-scheme-handler/unknown"     = [ "${default_browser}" ];
    };

  programs.firefox.policies.ExtensionSettings = {
    # about:support
    # about:policies#documentation
    # https://discourse.nixos.org/t/declare-firefox-extensions-and-settings/3625
   "{a8332c60-5b6d-41ee-bfc8-e9bb331d34ad}"   = { # vim mode - "gp" to go to sound playing tab
     install_url = "https://addons.mozilla.org/firefox/downloads/latest/surfingkeys_ff/latest.xpi";
     installation_mode = "force_installed";
     };
    "{aecec67f-0d10-4fa7-b7c7-609a2db280cf}"   = { # my custom javascript addons
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/violentmonkey/latest.xpi";
      installation_mode = "force_installed";
      };
  # add geminize?
    };


    programs.firefox.profiles.user = {
    id              = 0;
    isDefault       = true;
    containersForce = lib.mkForce true; # WARN: DO NOT TOGGLE THIS ! It erases previous containers
    search.force    = true;             # Keep search settings together with the following
    search.default  = "qwant"; # WARN: this value is referenced by thunderbird, which cannot use policies
    containers = {
      pro      = { id = 2; name  = "pro";    color = "orange";    icon  = "briefcase"; };
      goog     = { id = 1; name  = "Google"; color = "turquoise"; icon  = "pet";       };
      };
    };

  xdg.desktopEntries.firefox_private = {
    name         = "Firefox private";
    genericName  = "private incognito mode browser";
    icon         = "firefox-nightly";
    terminal     = false;
    categories   = [ "Network" "WebBrowser" ];
    exec         = "${lib.getExe config.programs.firefox.package} --private-window";
    };

  stylix.image = ./wallpaper_001.jpg;
  # Make wallpaper available to other apps e.g.pcmanfm-qt
  xdg.dataFile."wallpaper.jpg".source = config.stylix.image;

  };
}
