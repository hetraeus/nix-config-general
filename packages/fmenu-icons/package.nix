{ perSystem = { pkgs, lib, ... }:
  let
    # ── 1. Options module ──
    fmenuOptionsModule = { lib, ... }: {
      options.fmenu-icons = {
        iconsPack = lib.mkOption {
          type    = lib.types.package;
          default = pkgs.adwaita-icon-theme;
          description = "Icon theme package to browse.";
        };
        iconsVariant = lib.mkOption {
          type    = lib.types.str;
          default = "";
          description = "Icon theme variant subdirectory name.";
        };
      };
    };

    # ── 2. Builder function ──
    mkFmenuIcons = userModule:
      let
        cfg = (lib.evalModules { modules = [ fmenuOptionsModule userModule ]; }).config;
        iconsPack    = cfg.fmenu-icons.iconsPack;
        iconsVariant = cfg.fmenu-icons.iconsVariant;

        script = pkgs.writeShellApplication {
          name          = "fmenu-icons";
          runtimeInputs = [ pkgs.findutils pkgs.fzf pkgs.kitty ];
          text = ''
            find -L ${iconsPack}/share/icons/${iconsVariant} \
              \( -iname '*.svg' -o -iname '*.png' \) \
            | fzf \
              --preview-window=left,12%,border-none,wrap \
              --preview='sleep .1 ; kitten icat --clear --transfer-mode=memory --stdin=no {}' \
              --gutter=' ' \
              --delimiter='/' --with-nth=8..
          '';
        };

        desktopItem = pkgs.makeDesktopItem {
          name        = "Icons fuzzy chooser";
          exec        = "${pkgs.kitty} fmenu-icons";
          desktopName = "icon picker";
          categories  = [ "Graphics" ];
          icon        = "icons";
        };
      in
      pkgs.buildEnv {
        name  = "fmenu-icons-wrapper";
        meta.mainProgram = "fmenu-icons";
        paths = [ script desktopItem ];
      };

  in {
    # Default package (uses defaults)
    packages.fmenu-icons = mkFmenuIcons {};
    # Expose builder for overrides
    legacyPackages.fmenu-iconsWith = mkFmenuIcons;
  };
}
