{ perSystem = { pkgs, lib, self', ... }:
  let
    # ── 1. Options module ──
    piemenuOptionsModule = { lib, ... }: {
      options.piemenu-launch = {
        base01 = lib.mkOption {
          type    = lib.types.str;
          default = "#199CA8";
          description = "Button color.";
        };
        base0D = lib.mkOption {
          type    = lib.types.str;
          default = "#A532B5";
          description = "Text color.";
        };
      };
    };

    # ── 2. Builder function ──
    mkPiemenuLaunch = userModule:
      let
        cfg = (lib.evalModules { modules = [ piemenuOptionsModule userModule ]; }).config;

        piemenu-1   = pkgs.callPackage ./_piemenu.nix { inherit self'; };
        piemenu-2   = pkgs.runCommand "piemenu-2" {} ''
          mkdir --parent $out/bin
          ln --symbolic ${lib.getExe piemenu-1} $out/bin/piemenu_2
        '';
        rasi-theme  = pkgs.writeTextFile {
          name = "rasi-theme";
          text = builtins.readFile ./pie_model.rasi;
        };
        rasi-colors = "* { button: ${cfg.piemenu-launch.base01} ; tcolor: ${cfg.piemenu-launch.base0D} ; bg: #181515e2; }";

      in pkgs.writeShellApplication {
        name          = "piemenu-launch";
        runtimeInputs = [ pkgs.procps pkgs.rofi self'.packages.mouse-pos ];
        text = ''
          pkill --exact "rofi" && exit
          case "''${1:-kb}" in
            "kb") COMMAND=${lib.getExe  piemenu-1            };;
            "wm") COMMAND=${lib.getExe' piemenu-2 "piemenu_2"};;
            "*" ) exit ;;
          esac
          CURPOS="$(mouse-pos)"
          CURX="$(( ''${CURPOS% *} - 135 ))"
          CURY="$(( ''${CURPOS#* } - 125 ))"
          rofi                        \
          -p ""                       \
          -monitor -3                 \
          -selected-row 17            \
          -show   piemenu             \
          -theme  ${rasi-theme}       \
          -modes "piemenu:$COMMAND"   \
          -theme-str "${rasi-colors}
          window { x-offset: ''${CURX}px; y-offset: ''${CURY}px; }"
        '';
      };
  in {
    # Default package (uses defaults)
    packages.piemenu-launch = mkPiemenuLaunch {};
    # Expose builder for overrides
    legacyPackages.piemenu-launchWith = mkPiemenuLaunch;
  };
}
