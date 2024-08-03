{ config, lib, pkgs, ... }: let
  cfg     = config.programs.qimgv;
  iniFormat = pkgs.formats.ini { };

in {
  meta.maintainers = [ lib.maintainers.hetraeus ];

  options.programs.qimgv = {
    enable = lib.mkEnableOption "qimgv image viewer";

    package = lib.mkPackageOption pkgs "qimgv" { };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      example = lib.literalExpression "[ pkgs.rofi pkgs.gmic ];";
      description = ''
        Additional qimgv packages to install.
      '';
    };

    settings = lib.mkOption {
      type = iniFormat.type;
      default = { };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/qimgv.conf`
      ''; # TODO add man page
      example = lib.literalExpression ''
        {
          General = {
            slideshowInterval = 3000;
            mpvBinary = ''${pkgs.mpv}
          };
          Controls = {
            shortcuts = builtins.concatStringsSep ", " [
              "nextImage=<"
              "prevImage=>"
            ];
          }
        }
      '';
    };

    accentColor = lib.mkOption {
      default = "#8c9b81";
      example = "#aaa000";
      type = lib.types.str;
      description = "Accent color value.";
    };

    backgroundColor = lib.mkOption {
      default = "#1a1a1a";
      example = "#000000";
      type = lib.types.str;
      description = "Background color value.";
    };

    backgroundFullscreenColor = lib.mkOption {
      default = "#1a1a1a";
      example = "#000000";
      type = lib.types.str;
      description = "Fullscreen background color value.";
    };

    folderviewColor = lib.mkOption {
      default = "#242424";
      example = "#000000";
      type = lib.types.str;
      description = "Folder view color value.";
    };

    folderviewTopbarColor = lib.mkOption {
      default = "#383838";
      example = "#000000";
      type = lib.types.str;
      description = "Folder view topbar color value.";
    };

    iconsColor = lib.mkOption {
      default = "#a4a4a4";
      example = "#000000";
      type = lib.types.str;
      description = "Icons color value.";
    };

    overlayColor = lib.mkOption {
      default = "#1a1a1a";
      example = "#000000";
      type = lib.types.str;
      description = "Overlay color value.";
    };

    overlayTextColor = lib.mkOption {
      default = "#d2d2d2";
      example = "#000000";
      type = lib.types.str;
      description = "Overlay text color value.";
    };

    scrollbarColor = lib.mkOption {
      default = "#5a5a5a";
      example = "#000000";
      type = lib.types.str;
      description = "Scrollbar color value.";
    };

    textColor = lib.mkOption {
      default = "#b6b6b6";
      example = "#000000";
      type = lib.types.str;
      description = "Text color value.";
    };

    widgetColor = lib.mkOption {
      default = "#252525";
      example = "#000000";
      type = lib.types.str;
      description = "Widget color value.";
    };

    widgetBorderColor = lib.mkOption {
      default = "#2c2c2c";
      example = "#000000";
      type = lib.types.str;
      description = "Widget border color value.";
    };

  };

  config = lib.mkIf cfg.enable {
    # assertions =
    #   [ (lib.hm.assertions.assertPlatform "programs.qimgv" pkgs lib.platforms.linux) ];

    home.packages = [ cfg.package ] ++ cfg.extraPackages;

    xdg.configFile."qimgv/theme.conf".text = ''
      [Colors]
      tid=-1
      accent = ${cfg.accentColor}
      background = ${cfg.backgroundColor}
      background_fullscreen = ${cfg.backgroundFullscreenColor}
      folderview = ${cfg.folderviewColor}
      folderview_topbar = ${cfg.folderviewTopbarColor}
      icons = ${cfg.iconsColor}
      overlay = ${cfg.overlayColor}
      overlay_text = ${cfg.overlayTextColor}
      scrollbar = ${cfg.scrollbarColor}
      text = ${cfg.textColor}
      widget = ${cfg.widgetColor}
      widget_border = ${cfg.widgetBorderColor}
    '';

    xdg.configFile."qimgv/qimgv.conf" = {
      source = #lib.concatLines [
        iniFormat.generate "qimgv.conf" (
          lib.recursiveUpdate {
            General = let
              version = lib.getVersion cfg.package;
            in {
              firstRun = 0;
              lastVerMajor="${builtins.elemAt (builtins.splitVersion version) 0}";
              lastVerMinor="${builtins.elemAt (builtins.splitVersion version) 1}";
              lastVerMicro="${builtins.elemAt (builtins.splitVersion version) 2}";
            };
          } cfg.settings );
 #         cfg.extraConfig
#        ];

# printf '%s\n' "a_script %file%" | xxd -p | tr -d '\n' | sed 's/$..$/\\x\1/g'
    };
  };
}
