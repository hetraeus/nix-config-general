{ inputs, ... }: {
  perSystem = { lib, pkgs, self', ... }:
    let
      # ── Options module: your custom configurable values ──
      mpvOptionsModule = { lib, config, ... }: {
        options = {
          subs_langs_dw = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = "Language codes passed to subs-clean for downloading.";
            default = [ "en" ];
          };
          subs_player_langs = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = "Subtitle language preferences for mpv (slang=).";
            default = [ "en" ];
          };
          audio_player_langs = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = "Audio language preferences for mpv (alang=).";
            default = [ "en" ];
          };
          mpvStyle = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            description = "Key-value pairs for mpv.conf styling options.";
            default = {
              background = "#000000";
              osd-back-color = "#2c393f";
              osd-border-color = "#2c393f";
              osd-color = "#89ddff";
              osd-shadow-color = "#263238";
              osd-font = "Roboto";
              sub-font = "Roboto";
            };
          };
        };
      };

      # ── Builder function: accepts a module override, returns the mpv derivation ──
      mkMpv = userModule:
        let
          # Evaluate options: defaults merged with user overrides
          evaluated = lib.evalModules {
            modules = [ mpvOptionsModule userModule ];
          };
          cfg = evaluated.config;

          # Derived values from resolved config
          needsRoboto = cfg.mpvStyle.osd-font == "Roboto" || cfg.mpvStyle.sub-font == "Roboto";
          styleLines = lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "${k}=${v}") cfg.mpvStyle);
          subsLangLines = lib.concatStringsSep "\n" (map (lang: "slang=${lang}") cfg.subs_player_langs);
          audioLangLines = lib.concatStringsSep "\n" (map (lang: "alang=${lang}") cfg.audio_player_langs);

          subsList = builtins.readFile ../subs-clean/list;
          filterLines = lib.concatMapStringsSep "\n"
            (line: "sub-filter-regex-append=" + line)
            (lib.filter (l: l != "") (lib.splitString "\n" subsList));

          # Reusable helpers for input.conf
          black-and-white-hook = pkgs.writeText "black-and-white.hook" ''
            //!HOOK CHROMA
            //!BIND HOOKED
            //!DESC bChroma
            vec4 hook(){ return vec4(0.5); }
          '';

          back-to-caller-sh = pkgs.writeShellApplication {
            runtimeInputs = [ pkgs.procps pkgs.gnugrep self'.packages.wdotool ];
            name = "back-to-caller-sh";
            text = ''
              wdotool getwindowclassname "$(wdotool getactivewindow 2>/dev/null)" | grep --quiet '^mpv$' && {
                MPV_PARENT_PID="$(ps -o ppid= -p "$1")"
                hyprctl dispatch "hl.dsp.focus({ window = 'pid:""$MPV_PARENT_PID""' })" # wdotool doesn't work, don't know why
              }
            '';
          };
          back-to-caller-lua = pkgs.writeText "back-to-caller.lua" ''
            mp.register_event("shutdown", function ()
              os.execute("${lib.getExe back-to-caller-sh} " .. mp.get_property_native("pid"))
            end)
          '';
        in
        # ── Apply Lassulus/wrappers with resolved config ──
        (inputs.wrappers.wrapperModules.mpv.apply {
          inherit pkgs;
          extraPackages = [ pkgs.yt-dlp ] ++ lib.optional needsRoboto pkgs.roboto;
          scripts = [
            pkgs.mpvScripts.builtins.autocrop
            pkgs.mpvScripts.mpris
            pkgs.mpvScripts.quack
            pkgs.mpvScripts.vr-reversal
            pkgs.mpvScripts.sponsorblock
            pkgs.mpvScripts.thumbfast
            pkgs.mpvScripts.modernx-zydezu
          ];

          "mpv.conf".content =
            builtins.readFile ./mpv.conf
            + "\n" + styleLines
            + "\n" + subsLangLines
            + "\n" + audioLangLines
            + "\n" + filterLines;

          "input.conf".content = ''
            / script-binding select/select-subtitle-line
            0 add    volume   1
            1 ignore
            2 change-list glsl-shaders toggle "${black-and-white-hook}"
            3 ignore
            4 ignore
            5 ignore
            6 ignore
            7 ignore
            8 ignore
            9 add    volume  -1
            : script-binding console/enable
            < playlist_next
            > playlist_prev
            A ignore
            Alt+0 ignore
            Alt+1 ignore
            Alt+2 ignore
            Alt+x script-binding select/select-binding
            BS quit 4
            CTRL+l script-message switch-vf
            CTRL+p script-message switch-shaders
            Ctrl+1 add contrast   -1
            Ctrl+2 add contrast    1
            Ctrl+3 add brightness -1
            Ctrl+4 add brightness  1
            Ctrl+5 add gamma      -1
            Ctrl+6 add gamma       1
            Ctrl+7 add saturation -1
            Ctrl+8 add saturation  1
            Ctrl+S run ${lib.getExe' pkgs.xdg-utils "xdg-open"} "''${current-tracks/sub/external-filename}"; rescan-external-files
            Ctrl+c run ${lib.getExe' pkgs.wl-clipboard-rs "wl-copy"} -- ''${sub-text}
            Ctrl+f script-binding select/select-subtitle-line
            Ctrl+s run ${lib.getExe self'.packages.subs-clean} "''${path}/zzz_subtitles" "''${filename}" ${lib.concatStringsSep " " cfg.subs_langs_dw}; rescan-external-files
            DEL ignore
            DOWN seek       -60
            END seek        98  absolute-percent
            ENTER set speed 1.0
            F ignore
            F1 script-message playlist-view-close; script-message contact-sheet-toggle
            F2 script-message contact-sheet-close; script-message playlist-view-toggle
            G seek        98  absolute-percent
            HOME seek         0  absolute
            J ignore
            LEFT seek        -5
            N playlist-shuffle
            P show-progress
            PGDWN seek      -600
            PGUP seek       600
            RIGHT seek         5
            S cycle sub down
            STOP ignore
            Shift+PGDWN add    chapter -1
            Shift+PGUP add    chapter  1
            UP seek        60
            VOLUME_DOWN add    volume  -1
            VOLUME_UP add    volume   1
            ` ignore
            e ignore
            g seek         0  absolute
            j ignore
            m ignore
            o no-osd cycle-values osd-level 3 1
            s cycle sub
            t ignore
            v ignore
            x ignore
            { add audio-delay -0.100
            } add audio-delay  0.100
            ß cycle secondary-sid
          '';

          flags = {
            "--script" = "${back-to-caller-lua}";
            "--script-opts" = "ducksecs=2,duckratio=0.8,green_and_grumpy=true,window_controls=false,show_on_pause=false,bottom_hover=false,window_top_bar='no',seekbarfg_color='${cfg.mpvStyle.osd-color}'";
          };
        }).wrapper;
    in
    {
      # Default package with no overrides
      packages.mpv = mkMpv {};
      # Expose the builder for downstream customization
      legacyPackages.mpvWith = mkMpv;
    };
}
