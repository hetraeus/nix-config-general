{ flake.nixosModules.office = { pkgs, config, lib, ... }: {

  hardware.sane.enable = true;
  services.printing    = {
  #  logLevel = "debug";
    enable             = true;
    cups-pdf.enable    = true;
    startWhenNeeded    = true;
    drivers = [ pkgs.hplip ]; # 2025-11-26: yes I really need it. Check the printer with lpinfo -v
    };
  hardware.sane.extraBackends = [
    pkgs.sane-airscan
    pkgs.hplip # 2025-11-26: yes I really need it. Check the scanner with scanimage --list-devices
    ];


  services.opensnitch.rules.cups_snmp = {
    name        = "cups_snmp";
    created     = "2018-04-07T14:13:27.903996051+02:00"; # silence logs
    enabled     = true;
    action      = "allow";
    duration    = "always";
    operator    = {
      type      = "list";
      operand   = "list";
      sensitive = false;
      list      = [{
        type     = "regexp";
        operand  = "process.path";
        data     = "^/nix/store/[a-z0-9]{32}-cups-.*/lib/cups/backend/snmp";
        } {
        type    = "regexp";
        operand = "dest.ip";
        data    = "^(192\.168\.(1|122)\.255)$";
        } {
        type     = "simple";
        operand  = "protocol";
        data     = "udp";
        } {
        type     = "simple";
        operand  = "dest.port";
        data     = "161";
        }];
    };};

  services.udev.packages = [ pkgs.sane-airscan ];
  services.ipp-usb.enable=true;

  # INFO: Most printers manufactured after 2013 support the IPP Everywhere protocol,
  # i.e. printing without installing drivers. This is notably the case of all WiFi
  # printers marketed as Apple-compatible. Allow them with:
  services.avahi = { enable = true; nssmdns4 = true; openFirewall = true; };
  services.opensnitch.rules.awk_translator = {
    name        = "awk_translator";
      enabled   = true;
      created     = "2018-04-07T14:13:27.903996051+02:00"; # silence logs
      action    = "allow";
      duration  = "always";
      operator  = {
        type    = "list";
        operand = "list";
        list    = [{
        type    = "simple";
        operand = "process.path";
        data    = "${lib.getExe pkgs.gawk}";
        } {
        type    = "simple";
        operand = "dest.port";
        data    = "80";
        } {
        type    = "simple";
        operand = "dest.host";
        data    = "translate.googleapis.com";
        } {
        type    = "regexp";
        operand = "user.id";
        data    = "^(${toString config.users_list.principalUserUid})$";
        }];
    };};

};

flake.homeModules.office = { pkgs, lib, config, self, ... }: {

  home.packages = [
    # Note taking, alternative to Joplin
#    pkgs.logseq # 2026-06-02 unsafe !

    pkgs.libreoffice-qt6-fresh
    pkgs.onlyoffice-desktopeditors

    pkgs.marimo

    # infinite canvas note taking app
    pkgs.rnote

    # font readable to anyone
    pkgs.open-dyslexic

    # Casual font
    pkgs.nerd-fonts.recursive-mono

    # Europass CV fonts
    # find referenced fonts with inkscape pdf import or using
    # nix shell 'nixpkgs#poppler_utils' --command pdffonts "$PDF"
    pkgs.open-sans
    pkgs.font-awesome

    # scanners/pdf/ocr
    pkgs.ocrmypdf
    pkgs.naps2

    # pdf simple editor
    pkgs.pdfarranger

    # pdf/comic files reader
    pkgs.papers

    # website readability in terminal
    pkgs.reader

    pkgs.diff-pdf

    pkgs.libqalculate
    pkgs.qalculate-gtk
    self.packages.${pkgs.stdenv.hostPlatform.system}.printers-utils

    (self.legacyPackages.${pkgs.stdenv.hostPlatform.system}.ocr-batchWith {
      ocr-batch.langs = [ "eng" "ita" ];
      })
    ];
  #home.shellAliases.qalc = "echo -en \"\\e]2;🧮 qalc\\a\"; qalc --set=autocalc --set='temp 1'";
  #programs.qalculate.enable = true; # TEST
  programs.ripgrep-all.enable = true;
  programs.vivaldi.enable = true; # backup browser

  xdg.configFile."pdfarranger_config.ini" = { # disable "content-loss-warning"
    source = ./pdfarranger_config.ini ;
    target = "pdfarranger/config.ini" ;
    };

  xdg.mimeApps.associations.added = {
    "application/pdf" = lib.optionals config.programs.firefox.enable [ "firefox.desktop" ];
    };

  xdg.mimeApps.defaultApplications = {
    "application/epub+zip"          = [ "org.gnome.Papers.desktop" ];
    "application/pdf"               = [ "org.gnome.Papers.desktop" ];
    "application/vnd.comicbook+zip" = [ "org.gnome.Papers.desktop" ];
    "application/vnd.comicbook-rar" = [ "org.gnome.Papers.desktop" ];
    "image/vnd.djvu "               = [ "org.gnome.Papers.desktop" ];
    };
  };
}
