{ flake.nixosModules.network_webbrowser = { config, ... } : {

services.opensnitch.rules.kkk_firefox-80_443 = {
  name        = "kkk_firefox-80_443";
  enabled     = true;
  created     = "2010-01-01T10:00:00.000000Z"; # silence logs
  action      = "allow";
  duration    = "always";
  operator    = {
    type      = "list";
    operand   = "list";
    list      = [{
      type    = "regexp";
      operand = "protocol";
      data    = "^(tcp|udp)$";
      } {
      type    = "regexp";
      operand = "process.path";
      data    = "^/nix/store/[a-z0-9]{32}-firefox-.*/lib/firefox/firefox$";
      } {
      type    = "regexp";
      operand = "dest.port";
      data    = "^(80|443|3478)$";
      } {
      type    = "regexp";
      operand = "user.id";
      data    = "^(${toString config.users_list.principalUserUid})$";
      }];
};};

services.opensnitch.rules.koo_firefox-whatsapp-5222 = {
  name        = "koo_firefox-whatsapp-5222";
  created     = "2018-04-07T14:13:27.903996051+02:00"; # silence logs
  enabled     = true;
  action      = "allow";
  duration    = "always";
  operator    = {
    type      = "list";
    operand   = "list";
    list      = [{
      type    = "simple";
      operand = "protocol";
      data    = "tcp";
      } {
      type    = "regexp";
      operand = "process.path";
      data    = "^/nix/store/[a-z0-9]{32}-firefox-.*/lib/firefox/firefox$";
      } {
      type    = "simple";
      operand = "dest.port";
      data    = "5222";
      } {
      type    = "regexp";
      operand = "dest.host";
      data    = "^(|.*\.)whatsapp\.(com|net)$";
      } {
      type    = "regexp";
      operand = "user.id";
      data    = "^(${toString config.users_list.principalUserUid})$";
    }];
};};

services.opensnitch.rules.kop_firefox-whatsapp-ip-5222 = {
  name        = "kop_firefox-whatsapp-5222";
  created     = "2018-04-07T14:13:27.903996051+02:00"; # silence logs
  enabled     = true;
  action      = "allow";
  duration    = "always";
  operator    = {
    type      = "list";
    operand   = "list";
    list      = [{
      type    = "simple";
      operand = "protocol";
      data    = "tcp";
      } {
      type    = "regexp";
      operand = "process.path";
      data    = "^/nix/store/[a-z0-9]{32}-firefox-.*/lib/firefox/firefox$";
      } {
      type    = "simple";
      operand = "dest.port";
      data    = "5222";
      } {
      type    = "regexp";
      operand = "dest.ip";
      data    = "^(31.13.86.51)$";
      } {
      type    = "regexp";
      operand = "user.id";
      data    = "^(${toString config.users_list.principalUserUid})$";
    }];
};};

# backup browser
services.opensnitch.rules.kkk_vivaldi-80_443 = {
  name        = "kkk_vivaldi-80_443";
  enabled     = true;
  created     = "2018-04-07T14:13:27.903996051+02:00"; # silence logs
  action      = "allow";
  duration    = "always";
  operator    = {
    type      = "list";
    operand   = "list";
    list      = [{
      type    = "regexp";
      operand = "protocol";
      data    = "^(tcp|udp)$";
      } {
      type    = "regexp";
      operand = "process.path";
      data    = "^/nix/store/[a-z0-9]{32}-vivaldi-.*/opt/vivaldi/vivaldi-bin$";
      } {
      type    = "regexp";
      operand = "dest.port";
      data    = "^(80|443)$";
      } {
      type    = "regexp";
      operand = "user.id";
      data    = "^(${toString config.users_list.principalUserUid})$";
      }];
};};
};

flake.homeModules.network_webbrowser = { ... } : {
  programs.firefox.policies.Preferences  = let
    lock-false = { Value = false; Status = "locked"; };
    lock-true  = { Value = true;  Status = "locked"; };
    in {

    "widget.use-xdg-desktop-portal.file-picker"  = { Value = 1;  Status = "locked"; };
    "widget.use-xdg-desktop-portal.mime-handler" = { Value = 1;  Status = "locked"; };
    "widget.use-xdg-desktop-portal.settings"     = { Value = 1;  Status = "locked"; };
    "widget.use-xdg-desktop-portal.location"     = { Value = 1;  Status = "locked"; };
    "widget.use-xdg-desktop-portal.open-uri"     = { Value = 1;  Status = "locked"; };

    "mousewheel.min_line_scroll_amount"    = { Value = 7;  Status = "locked"; };
    "browser.startup.page"                 = { Value = 3;  Status = "locked"; }; # keep tabs between session
    # Remove dialogs
    "browser.aboutConfig.showWarning"      = lock-false;
    "browser.tabs.closeWindowWithLastTab"  = lock-false;
    "browser.warnOnQuitShortcut"           = lock-false;
    "browser.quitShortcut.disabled"        = lock-true; # disable ctrl+q
    # Alt + letter suggestions interferes with system key shortcuts
    "ui.key.menuAccessKeyFocuses"          = lock-false;
    # Use the operating system codecs
    "media.webspeech.synth.enabled"        = lock-false;
    };

programs.firefox.policies.ExtensionSettings = { # about:support
  "{531906d3-e22f-4a6c-a102-8057b88a1a63}"  = { # download website as single file
    install_url = "https://addons.mozilla.org/firefox/downloads/latest/single-file/latest.xpi";
    installation_mode = "force_installed";
    };
  "{287dcf75-bec6-4eec-b4f6-71948a2eea29}"  = { # better image viewer
    install_url = "https://addons.mozilla.org/firefox/downloads/latest/view-image/latest.xpi";
    installation_mode = "force_installed";
    };
  "{0981817c-71b3-4853-a801-481c90af2e8e}"  = { # jsonlz4 editor
    install_url = "https://addons.mozilla.org/firefox/downloads/latest/mozlz4-edit/latest.xpi";
    installation_mode = "force_installed";
    };
  "{ac34afe8-3a2e-4201-b745-346c0cf6ec7d}"  = { # youtube shorts controls
    install_url = "https://addons.mozilla.org/firefox/downloads/latest/better-youtube-shorts/latest.xpi";
    installation_mode = "force_installed";
    };
  "{3c6bf0cc-3ae2-42fb-9993-0d33104fdcaf}"  = { # youtube enhancements
    install_url = "https://addons.mozilla.org/firefox/downloads/latest/youtube-addon/latest.xpi";
    installation_mode = "force_installed";
    };
  "{a831defa-a6c9-4ca9-9593-9ccaf98462d9}"  = { # add player controls on instagram
    install_url = "https://addons.mozilla.org/firefox/downloads/latest/instagram-video-control/latest.xpi";
    installation_mode = "force_installed";
    };
  "{74108f18-bfa1-4cd3-a0b1-6c575ee3dce0}"  = { # websites list block
    install_url = "https://addons.mozilla.org/firefox/downloads/latest/blacklist-autoclose/latest.xpi";
    installation_mode = "force_installed";
    };
  "fbpElectroWebExt@fbpurity.com"           = {
    install_url = "https://www.fbpurity.com/fbpurity.THRTYX-WX.xpi";
    installation_mode = "force_installed";
    };
  # "jid1-xUfzOsOFlzSOXg@jetpack"           = { # reddit enhancements
  #   install_url = "https://addons.mozilla.org/firefox/downloads/latest/reddit-enhancement-suite/latest.xpi";
  #   installation_mode = "force_installed";
  #   };
  # "nextpage@yuanle.song"                  = { # press space -> go to next page
  #   install_url = "https://addons.mozilla.org/firefox/downloads/latest/nextpage/latest.xpi";
  #   installation_mode = "force_installed";
  #   };
  "printedit-we@DW-dev"                   = { # remove useless parts before printing a webpage
    install_url = "https://addons.mozilla.org/firefox/downloads/latest/print-edit-we/latest.xpi";
    installation_mode = "force_installed";
    };
  };


};}
