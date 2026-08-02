{ flake.nixosModules.pim = { config, pkgs, ... }: {

  services.opensnitch.rules.thb_enable_gmail = {
    name        = "thb_enable_gmail";
      enabled   = true;
      created   = "2010-01-01T10:00:00.000000000+01:00"; # silence logs
      action    = "allow";
      duration  = "always";
      operator  = {
        type    = "list";
        operand = "list";
        list    = [{
        type    = "simple";
        operand = "process.path";
        data    = "${pkgs.thunderbird}/lib/thunderbird/thunderbird";
        } {
        type    = "regexp";
        operand = "dest.port";
        data    = "^(53|443|465|993)$";
        } {
        type    = "regexp";
        operand = "dest.host";
        data    = "^(.*\.thunderbird\.net|www\.googleapis\.com|(lh3|apidata)\.googleusercontent\.com|imap\.gmail\.com)$";
        } {
        type    = "regexp";
        operand = "user.id";
        data    = "^(${toString config.users_list.principalUserUid})$";
        }];
    };};

};

flake.homeModules.pim = { lib, config, pkgs, self, ... }: {

  home.packages = [
    self.packages.${pkgs.stdenv.hostPlatform.system}.cdw
    self.packages.${pkgs.stdenv.hostPlatform.system}.cdw-timer
#    pkgs.lasuite-meet
    ];

  programs.thunderbird.enable = true;
  programs.thunderbird.profiles."user" = {
    isDefault      = true;
    search.force   = true;
    search.default = "${config.programs.firefox.profiles."user".search.default}";
    };

  systemd.user.services.thunderbird = {
    Service.ExecStart = "${lib.getExe config.programs.thunderbird.package}";
    Unit.Description  = "email client PIM";
    Unit.After        = [ "graphical-session.target" ] ;
    Unit.Wants        = [ "graphical-session.target" ] ;
    Install.WantedBy  = [ "graphical-session.target" ] ;
    };
  programs.thunderbird.policies.ExtensionSettings = { # about:support
    # https://thunderbird.github.io/policy-templates/
    "*".installation_mode = "blocked"; # blocks all addons except the ones specified below

  # WARN: it's probably better to not skip redirections from mail !
  # they may be useful for registratio to websites
  # "skipredirect@sblask"                         = {
  #   install_url = "https://addons.mozilla.org/firefox/downloads/latest/skip_redirect/latest.xpi";
  #   installation_mode = "force_installed";
  #   };
    };

  programs.thunderbird.settings = {
    # Alt + letter suggestions interferes with system key shortcuts
    "ui.key.menuAccessKeyFocuses"   = false;
    "mail.shell.checkDefaultClient" = false;
  #  "network.protocol-handler.warn-external.https" = true; # TEST: thunderbird wasn't choosing the right browser
  #  "network.protocol-handler.warn-external.http"  = true; # TEST
    #"mail.biff.use_system_alert" = true; # 2025-05-22 native notification, but they aren't working
    };
 };}
