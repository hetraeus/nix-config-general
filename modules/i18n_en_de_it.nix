{ flake.nixosModules.i18n_en_de_it = {
  time.timeZone = "Europe/Rome";
  services.xserver.xkb.layout  = "it";

  # To get localized time format with : env LC_TIME=it_IT.utf8 date
  i18n.extraLocales  = [ "it_IT.UTF-8/UTF-8" ];
  };

flake.homeModules.i18n_en_de_it = { config, pkgs, lib, self, ...}: {

  home.packages = [
    self.packages.${pkgs.stdenv.hostPlatform.system}.translat
    pkgs.gtt

  # LibreOffice / Firefox dictionaries
    pkgs.hunspell
    pkgs.hunspellDicts.en-us-large

  # LibreOffice / Firefox i18n dictionaries
    pkgs.hunspellDicts.it-it
    ];
  programs.firefox.languagePacks                   = [ "en-US" "it" ];
  programs.firefox.policies.Preferences            = {
    "browser.translations.neverTranslateLanguages" = { Value =  "en,it"; Status = "locked"; };
    "spellchecker.dictionary_path"                 = pkgs.symlinkJoin {
      name  = "firefox-hunspell-dicts";
      paths = [ pkgs.hunspellDicts.en-us-large pkgs.hunspellDicts.it-it ];
      } + "/share/hunspell";};
  programs.thunderbird.settings    = {
    "spellchecker.dictionary_path" = config.programs.firefox.policies.Preferences."spellchecker.dictionary_path"; #TEST:
    "spellchecker.dictionary"      = "en-US,it-IT";
    };

  programs.yt-dlp.settings.sub-langs               = "all";

  programs.translate-shell.enable    = true;
  home.shellAliases._ei = "${lib.getExe config.programs.translate-shell.package} en:it -- ";
  home.shellAliases._ie = "${lib.getExe config.programs.translate-shell.package} it:en -- ";
  home.shellAliases._de = "${lib.getExe config.programs.translate-shell.package} de:en -- ";
  home.shellAliases._fi = "${lib.getExe config.programs.translate-shell.package} fr:it -- ";
  home.shellAliases._fe = "${lib.getExe config.programs.translate-shell.package} fr:en -- ";
  home.shellAliases._si = "${lib.getExe config.programs.translate-shell.package} es:it -- ";
  home.shellAliases._is = "${lib.getExe config.programs.translate-shell.package} it:es -- ";

  xdg.desktopEntries.transl_en = {
    name         = "translate to english";
    exec         = "${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.translat} tr_notify en";
    terminal     = false;
    categories   = [ "Utility" ];
    genericName  = "🇬🇧";
    icon         = "flag";
    };

  xdg.desktopEntries.transl_it = {
    name         = "translate to italian";
    exec         = "${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.translat} tr_notify it";
    terminal     = false;
    categories   = [ "Utility" ];
    genericName  = "🇮🇹";
    icon         = "flag";
    };

  wayland.windowManager.hyprland.extraConfig = ''
    hl.config({ input = { kb_layout = "it", } })
    '';
  programs.firefox.policies."3rdparty".Extensions = {
    "uBlock0@raymondhill.net".adminSettings.selectedFilterLists = [ "ITA-0" ];};

  xdg.configFile."my_tesseract_config".text = ''
    language=eng+ita
    '';

};}
