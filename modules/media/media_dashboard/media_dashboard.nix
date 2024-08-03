{ flake.homeModules.media_dashboard = { config, pkgs, lib, self, ... }: let
  tui_mpd_client  = "${lib.getExe config.programs.rmpc.package} --address=$XDG_RUNTIME_DIR/mpd/socket";

in {
  home.packages = [
    self.packages.${pkgs.stdenv.hostPlatform.system}.fmenu-radio-mpd
    ];
  systemd.user.services.music_dashboard = let
    music_kitty_session = pkgs.writeText "music_kitty_session" ''
      enabled_layouts tall:bias=32;full_size=1
      launch ${lib.getExe pkgs.helix} ~/.cache/todo.asciidoc
      launch sh -c "while true; do sleep 1.4; ${tui_mpd_client} || ${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.fmenu-radio-mpd} ; done"
      launch sh -c "trap ''' 2; ${lib.getExe pkgs.pulsemixer} --color 1"
      launch kitty @ focus-window --match=cmdline:${tui_mpd_client}
      '';
  in {
    Service.ExecStart = "${lib.getExe pkgs.kitty} --app-id='music_dashboard' --title='🎧 music' --session=${music_kitty_session}";
    Unit.Description  = "music_dashboard";
    Unit.After        = [ "graphical-session.target" ] ;
    Unit.Wants        = [ "graphical-session.target" ] ;
    Install.WantedBy  = [ "graphical-session.target" ] ;
    };

  xdg.configFile."rmpc/themes/theme.ron".source = ./rmpc_theme.ron;

  home.shellAliases.mm   = "${tui_mpd_client}";
  home.shellAliases.rmpc = "${tui_mpd_client}";
  programs.rmpc.enable = true;
  programs.rmpc.config = ''
    #![enable(implicit_some)]
    #![enable(unwrap_newtypes)]
    #![enable(unwrap_variant_newtypes)]
    (
        address: "127.0.0.1:6600",
        password: None,
        theme: Some("theme"),
        cache_dir: Some("/tmp/mpc"),
        on_song_change: None,
        volume_step: 5,
        max_fps: 30,
        scrolloff: 50,
        wrap_navigation: false,
        enable_mouse: true,
        status_update_interval_ms: 1000,
        select_current_song_on_change: false,
        album_art: (
            method: Auto,
            max_size_px: (width: 1200, height: 1200),
            disabled_protocols: ["http://", "https://"],
            vertical_align: Center,
            horizontal_align: Center,
        ),
        keybinds: (
            global: {
                ":":       CommandMode,
                "s":       Stop,
                "9":       VolumeDown,
                "0":       VolumeUp,
                "<Tab>":   NextTab,
                "<S-Tab>": PreviousTab,
                "1":       SwitchToTab("Queue"),
                "2":       SwitchToTab("Directories"),
                "3":       SwitchToTab("Artists"),
                "4":       SwitchToTab("Album Artists"),
                "5":       SwitchToTab("Albums"),
                "6":       SwitchToTab("Playlists"),
                "7":       SwitchToTab("Search"),
                "q":       Quit,
                "p":       TogglePause,
                "<":       NextTrack,
                ">":       PreviousTrack,
                "f":       SeekForward,
                "z":       ToggleRepeat,
                "x":       ToggleRandom,
                "c":       ToggleConsume,
                "v":       ToggleSingle,
                "b":       SeekBack,
                "<F1>":    ShowHelp,
                "I":       ShowCurrentSongInfo,
                "O":       ShowOutputs,
                "P":       ShowDecoders,
                "<A-x>":   ExternalCommand(command: ["${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.fmenu-selsong}", "arg1", "arg2"], description: "Song menu"),
            },
            navigation: {
                "k":         Up,
                "j":         Down,
                "h":         Left,
                "l":         Right,
                "<Up>":      Up,
                "<Down>":    Down,
                "<Left>":    Left,
                "<Right>":   Right,
                "<C-k>":     PaneUp,
                "<C-j>":     PaneDown,
                "<C-h>":     PaneLeft,
                "<C-l>":     PaneRight,
                "<C-u>":     UpHalf,
                "a":         Add,
                "A":         AddAll,
                "r":         Rename,
                "<F2>":      Rename,
                "N":         PreviousResult,
                "n":         NextResult,
                "<Space>":   Select,
                "<C-Space>": InvertSelection,
                "g":         Top,
                "G":         Bottom,
                "<CR>":      Confirm,
                "i":         FocusInput,
                "J":         MoveDown,
                "<C-d>":     DownHalf,
                "/":         EnterSearch,
                "<C-c>":     Close,
                "<Esc>":     Close,
                "K":         MoveUp,
                "<Del>":     Delete,
                "<PageUp>":  UpHalf,
                "<PageDown>":  DownHalf,
            },
            queue: {
                "D":       DeleteAll,
                "<CR>":    Play,
                "<C-s>":   Save,
                "a":       AddToPlaylist,
                "d":       Delete,
                "i":       ShowInfo,
                "C":       JumpToCurrent,
            },
        ),
        search: (
            case_sensitive: false,
            mode: Contains,
            tags: [
                (value: "any",         label: "Any Tag"),
                (value: "artist",      label: "Artist"),
                (value: "album",       label: "Album"),
                (value: "albumartist", label: "Album Artist"),
                (value: "title",       label: "Title"),
                (value: "filename",    label: "Filename"),
                (value: "genre",       label: "Genre"),
            ],
        ),
        artists: (
            album_display_mode: SplitByDate,
            album_sort_by: Date,
        ),
        tabs: [
            (
                name: "Queue",
                pane: Split(
                    direction: Horizontal,
                    panes: [(size: "30%", pane: Pane(AlbumArt)), (size: "70%", pane: Pane(Queue))],
                ),
            ),
            (
                name: "Directories",
                pane: Pane(Directories),
            ),
            (
                name: "Artists",
                pane: Pane(Artists),
            ),
            (
                name: "Album Artists",
                pane: Pane(AlbumArtists),
            ),
            (
                name: "Albums",
                pane: Pane(Albums),
            ),
            (
                name: "Playlists",
                pane: Pane(Playlists),
            ),
            (
                name: "Search",
                pane: Pane(Search),
            ),
        ],
    )
  '';

};}
