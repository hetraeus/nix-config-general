{ pkgs, ... } : let
  ENGLISH_OVERRIDE="en_DK.UTF-8"; # Euro English
in {

  i18n = {
    defaultLocale     = "en_US.UTF-8";
    extraLocales  = [
      # Fallback
      "${ENGLISH_OVERRIDE}/UTF-8"
  ]; };

  i18n.extraLocaleSettings = {
  # WARN: DONT REMOVE THESE EXAMPLES
  # MAX PRECEDENCE OVERRIDE, so DON'T USE IT ! It is intended as an interactive override
  # LANGUAGE          = "en_DK.UTF-8";

  # MIN PRECEDENCE OVERRIDE, so don't use it !i It is intended as an interactive override
  # LC_ALL            = "it_IT.UTF-8";

  # Character classification, it makes to work tolower, to upper, isalpha, sort, etc
    LC_CTYPE          = "${ENGLISH_OVERRIDE}";

    LC_ADDRESS        = "${ENGLISH_OVERRIDE}";
    LC_COLLATE        = "${ENGLISH_OVERRIDE}";
    LC_IDENTIFICATION = "${ENGLISH_OVERRIDE}";
    LC_MEASUREMENT    = "${ENGLISH_OVERRIDE}";
    LC_MESSAGES       = "${ENGLISH_OVERRIDE}";
    LC_MONETARY       = "${ENGLISH_OVERRIDE}";
    LC_NAME           = "${ENGLISH_OVERRIDE}";
    LC_NUMERIC        = "${ENGLISH_OVERRIDE}";
    LC_PAPER          = "${ENGLISH_OVERRIDE}";
    LC_TELEPHONE      = "${ENGLISH_OVERRIDE}";
    LC_TIME           = "${ENGLISH_OVERRIDE}";
    };

  # use Xorg/xkb.options in tty
  console.useXkbConfig = true;
  services.kmscon.useXkbConfig = true;
  services.kmscon.fonts = [ { name = "Iosevka NFM"; package = pkgs.nerd-fonts.iosevka; } ];

  # touchpad
  services.libinput.enable = true;

  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
  '';

  documentation.man.mandoc.settings.output.paper = "a4";
}
