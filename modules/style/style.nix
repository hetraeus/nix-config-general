{ flake.homeModules.style = { pkgs, lib, config, self, ... } : let
  buttonColor = config.lib.stylix.colors.withHashtag.base0D;
  backColor   = config.lib.stylix.colors.withHashtag.base01;
  textColor   = config.lib.stylix.colors.withHashtag.base05;
  fgColor     = config.lib.stylix.colors.withHashtag.base0E;

in {
  imports = [
    ./_style_ff_userchrome.nix
    ./_style_notification_panel.nix
    ];
  home.packages = [
    (self.legacyPackages.${pkgs.stdenv.hostPlatform.system}.fmenu-iconsWith {
      fmenu-icons.iconsPack    = config.stylix.icons.package;
      fmenu-icons.iconsVariant = config.stylix.icons.light;
      })
    pkgs.cabin
    pkgs.noto-fonts-cjk-sans
    self.packages.${pkgs.stdenv.hostPlatform.system}.fmenu-prewfont
  ];
  fonts.fontconfig.enable = true;
  stylix.fonts  = {
    serif       = { name = "Noto Serif"       ; package = pkgs.noto-fonts             ;};
    sansSerif   = { name = "Roboto"           ; package = pkgs.roboto                 ;};
    emoji       = { name = "Noto Color Emoji" ; package = pkgs.noto-fonts-color-emoji ;};
    monospace   = { name = "Iosevka NFM"      ; package = pkgs.nerd-fonts.iosevka     ;};
  #sansSerif   = { name = "Ubuntu"           ; package = pkgs.ubuntu_font_family ;};
    sizes.applications  = 12;
    sizes.terminal      = 13;
    };
    
  xdg.configFile."rofi/themes/accent_colors_list.rasi".text = "* { textcol: ${textColor}; bg: ${backColor}e2; button: ${buttonColor}; fg: ${fgColor}; }" ;

  xdg.configFile."terminal-colors.d/cal.scheme".text = ''
    today   33;42
    weeknumber 33
    weeks      32
    header     32
    workday    37
    weekend    35
  '';

  programs.fzf.colors = {
    "bg+" = lib.mkForce config.lib.stylix.colors.withHashtag.base0B;
    "fg+" = lib.mkForce "#ffffff";
    };

  gtk.enable   = true;
  qt.enable    = true;
  stylix.icons = {
    enable     = true;
    package    = pkgs.dracula-icon-theme ;
    dark       = "Dracula";
    light      = "Dracula";
    };

  stylix             = {
    enable           = true;
    opacity.terminal = 0.95;
    # Gallery : https://tinted-theming.github.io/tinted-gallery/
    base16Scheme     = "${pkgs.base16-schemes}/share/themes/materia.yaml"; # oceanicnext.yaml";
    #base16Scheme     = "${pkgs.base16-schemes}/share/themes/rose-pine-moon.yaml"; # oceanicnext.yaml";
    # base16Scheme     = "${pkgs.base16-schemes}/share/themes/harmonic16-dark.yaml"; # measured-light.yaml";
    polarity         = "dark";
    };

  # /run/current-system/specialisation/day/bin/switch-to-configuration switch
  # nixos-rebuild switch --specialisation light
  specialisation.day.configuration.stylix = {
    polarity        = lib.mkForce "light";
    base16Scheme    = lib.mkForce "${pkgs.base16-schemes}/share/themes/catppuccin-latte.yaml";
    };

  stylix.cursor = {
    #name = "layan-cursors-white";
    #package = layan_cursors_white;
    name = "Simp1e-Catppuccin-Frappe";
    package = pkgs.simp1e-cursors;
    size    = 32;
    };

#  wayland.windowManager.hyprland.settings.general."col.inactive_border" = lib.mkForce "rgb(272727)";

  programs.hyprlock.settings = {
    animations.enabled  = false;
    general.hide_cursor =  true;
    animation = [
    "workspaces, 1, 4, default, slidevert"
    "windows, 1, 4, default, popin"
    "layers, 1, 2, default, popin"
    "fadePopups, 0, 0, default"
    "fadeOut, 0, 0, default"
    ];
   };

  #programs.hyprlock.settings.background = [ {
  #  monitor     = "";
  #  path        = "${config.stylix.image}";
  #  color       = "rgba(4, 29, 33, 1.0)";
  #  blur_size   = 5;
  #  blur_passes = 0;
  #  } ];

  programs.hyprlock.settings.label = [ { # Clock
    monitor               = "";
    text                  = "$TIME";
    font_size             = 65;
    color                 = "rgba(${config.lib.stylix.colors.base0D-rgb-r}, ${config.lib.stylix.colors.base0D-rgb-g}, ${config.lib.stylix.colors.base0D-rgb-b}, 1.0)";

    position              = "5%, -22%";
    halign                = "center";
    valign                = "top";

    } { # keyboard layout
    monitor               = "";
    text                  = "keyboard layout : $LAYOUT[it,en]";
    font_size             = 15;
    color                 = "rgba(${config.lib.stylix.colors.base0D-rgb-r}, ${config.lib.stylix.colors.base0D-rgb-g}, ${config.lib.stylix.colors.base0D-rgb-b}, 1.0)";

    position              = "5%, 0%";
    halign                = "center";
    valign                = "top";

    } { # caps on/off
    monitor               = "";
    text                  = "cmd[update:500] [ $(head --lines=1 /sys/class/leds/input*::capslock/brightness) = 1 ] && echo 'CAPS ON'";
    color                 = "rgba(255, 0, 0, 1.0)";
    font_size             = 20;
    font_family           = "${config.stylix.fonts.sansSerif.name}, bold";

    halign                = "center";
    valign                = "center";
    position              = "0, -300";
    } ];


  programs.hyprlock.settings.input-field = {
    monitor           = "";
    size              = "200, 50";
    outline_thickness = 3;
    dots_size         = "0.33"; # Scale of input-field height, 0.2 - 0.8
    dots_spacing      = "0.15"; # Scale of dots' absolute size, 0.0 - 1.0
    dots_center       = true;
    dots_rounding     = -1; # -1 default circle, -2 follow input-field rounding
  # inner_color       = "rgba(240, 240, 250, 1.0)";
  # font_color        = "rgb(10, 10, 10)";
    fade_on_empty     = true;
    fade_timeout      = 0; # Milliseconds before fade_on_empty is triggered.
    placeholder_text  = "<i>:'(</i>"; # Text rendered in the input box when it's empty.
    hide_input        = false;
    rounding          = 10; # -1 means complete rounding (circle/oval)
  # check_color       = "rgb(204, 136, 34)";
  # fail_color        = "rgb(204, 34, 34)"; # if authentication failed, changes outer_color and fail message color
    fail_text         = "<i>$FAIL <b>($ATTEMPTS)</b></i>"; # can be set to empty
  #  fail_transition   = 0; # transition time in ms between normal outer_color and fail_color
  # capslock_color    = -1;
  # numlock_color     = -1;
  # bothlock_color    = -1; # when both locks are active. -1 means don't change outer color (same for above)
    invert_numlock    = false; # change color if numlock is off
    swap_font_color   = false; # see below

    position          = "0, 0";
    halign            = "center";
    valign            = "bottom";
    };

};}
