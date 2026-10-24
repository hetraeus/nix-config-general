{ ... }: { flake.nixosModules.desktop_shell = { pkgs, config, lib, ... }: {

  environment.systemPackages = [
    pkgs.brightnessctl
    pkgs.wlr-randr
    ];

  # Realtime scheduling priority to user processes on demand
  security.rtkit.enable    = true;

  # GTK+ applications configuration, needed by home-manager > easyeffect
  programs.dconf.enable    = true;

  environment.pathsToLink = [ "/share/xdg-desktop-portal" "/share/applications" ]; # allow portals in home manager

  # mount
  services.gvfs.enable     = true;
  services.udisks2.enable  = true; # needed by udiskie
  # services.tumbler.enable  = true;
  # programs.xfconf.enable   = true;
  # programs.thunar.enable   = true;
  # programs.thunar.plugins = with pkgs; [ thunar-archive-plugin thunar-volman thunar-vcs-plugin thunar-shares-plugin thunar-media-tags-plugin ];

  # Should withelist wttr.in , but sometimes is not online. Can I replace it?

  services.opensnitch.rules.shell-noctalia = {
    name        = "shell-noctalia";
    created     = "2010-01-01T10:00:00.000000Z"; # silence logs
    enabled     = true;
    action      = "allow";
    duration    = "always";
    operator    = {
      type      = "list";
      operand   = "list";
      sensitive = false;
      list      = [{
        type    = "regexp";
        operand = "dest.host";
        data    = "^(api\.open-meteo\.com|noctalia\.cachix\.org)$";
        } {
      type      = "regexp";
       operand  = "dest.port";
       data     = "(53|443)";
       }];
    };};

  services.opensnitch.rules.nct_ytthumbnail = {
    name      = "nct_ytthumbnail";
    enabled   = true;
    created     = "2010-01-01T10:00:00.000000Z"; # silence logs
    action    = "allow";
    duration  = "always";
    operator  = {
      type    = "list";
      operand = "list";
      list    = [{
      type    = "regexp";
      operand = "process.path";
      data    = "^(/nix/store/[a-z0-9]{32}-noctalia-.*/bin/\.noctalia-wrapped)$";
      } {
      type    = "simple";
      operand = "dest.port";
      data    = "443";
      } {
      type    = "regexp";
      operand = "dest.host";
      data    = "^(i\.ytimg\.com)$";
      }];
  };};

  services.opensnitch.rules.wttr_weather = {
    name      = "wttr_weather";
    enabled   = true;
    created     = "2010-01-01T10:00:00.000000Z"; # silence logs
    action    = "allow";
    duration  = "always";
    operator  = {
      type    = "list";
      operand = "list";
      list    = [{
      type    = "regexp";
      operand = "process.path";
      data    = "^(/nix/store/[a-z0-9]{32}-python3-.*/bin/python3\..*)$";
      } {
      type    = "simple";
      operand = "dest.port";
      data    = "443";
      } {
      type    = "regexp";
      operand = "dest.host";
      data    = "^(wttr\.in)$";
      } {
      type    = "regexp";
      operand = "user.id";
      data    = "^(${toString config.users_list.principalUserUid})$";
      } {
      type    = "regexp";
      operand = "process.command";
      data    = "^(/etc/profiles/per-user/${config.users_list.principalUser}/bin/weather .*)$";
      }];
  };};
  };

flake.homeModules.desktop_shell = { pkgs, lib, config, self, ... }: {

  home.packages = [
    self.packages.${pkgs.stdenv.hostPlatform.system}.weather
    self.packages.${pkgs.stdenv.hostPlatform.system}.hyprnotipick
    self.packages.${pkgs.stdenv.hostPlatform.system}.url-unshorten

    self.packages.${pkgs.stdenv.hostPlatform.system}.qr-selectread
    self.packages.${pkgs.stdenv.hostPlatform.system}.qr-code-from-clipboard
    self.packages.${pkgs.stdenv.hostPlatform.system}.cam-reader

    pkgs.gcolor3
    pkgs.wl-clipboard-rs
    pkgs.glib # allow gio trash, gio rm and other xdg desktop aware commands
    pkgs.playerctl

    pkgs.zbar
    pkgs.zint-qt
    ];

  multiverse.pins = {
    noctalia = "5.2.1";
    };
  programs.noctalia.package = config.multiverse.pinned.noctalia;

    
  programs.noctalia.enable = true;
  programs.noctalia.systemd.enable = true;
  programs.noctalia.settings = ''
      config_version = 14

      [accessibility]
      ui_scale = 1.1000000089406967

      [audio]
      enable_sounds = false

      [bar]
      order = [ "default", "scroller_bar" ]

          [bar.default]
          auto_hide = true
          border = "secondary"
          border_width = 1.5
          capsule_padding = 11.0
          capsule_thickness = 0.83999998494982719
          end = [
              "volume",
              "spacer_5",
              "brightness",
              "spacer_5",
              "battery",
              "spacer_5",
              "network",
              "spacer_5",
              "bluetooth",
              "tray"
          ]
          layer = "overlay"
          margin_edge = 2
          margin_ends = 360
          position = "bottom"
          radius = 6
          reserve_space = false
          shadow = false
          show_on_workspace_switch = false
          start = [ "weather", "spacer_4", "media" ]

              [bar.default.dead_zone.actions]
              right = "none"

          [bar.scroller_bar]
          background_opacity = 0.0
          center = [ "notifications", "spacer_3", "workspaces" ]
          enabled = true
          end = []
          layer = "overlay"
          margin_ends = 410
          padding = 8
          position = "right"
          reserve_space = false
          shadow = false
          smart_auto_hide = true
          start = []

      [control_center]
      sidebar = "full"

          [control_center.calendar]
          show_week_numbers = true

          [[control_center.shortcuts]]
          type = "caffeine"

          [[control_center.shortcuts]]
          type = "nightlight"

          [[control_center.shortcuts]]
          type = "power_profile"

      [desktop_widgets]
      schema_version = 2
      widget_order = []

          [desktop_widgets.grid]
          cell_size = 16
          major_interval = 4
          visible = true

          [desktop_widgets.widget]

      [dock]
      background_opacity = 0.0
      icon_size = 31
      position = "right"
      reserve_space = false
      shadow = false
      smart_auto_hide = true

      [hot_corners]
      enabled = true

      [idle]
      behavior_order = [ "lock", "screen-off", "lock-and-suspend" ]
      pre_action_fade_seconds = 10

          [idle.behavior.lock]
          action = "lock"
          enabled = true
          timeout = 540.0

          [idle.behavior.lock-and-suspend]
          action = "lock_and_suspend"
          enabled = true
          timeout = 900.0

          [idle.behavior.screen-off]
          action = "screen_off"
          enabled = true
          locked_timeout = 30.0
          timeout = 530.0

      [lockscreen]
      wallpaper = "${config.stylix.image}"
      transition = [] # empty disables lock/unlock animation

      [lockscreen_widgets]
      enabled = true
      schema_version = 2
      widget_order = [ "lockscreen-login-box@eDP-1", "lockscreen-widget-0000000000000001" ]

          [lockscreen_widgets.grid]
          cell_size = 16
          major_interval = 4
          visible = true

          [lockscreen_widgets.widget."lockscreen-login-box@eDP-1"]
          box_height = 150.0
          box_width = 810.0
          cx = 960.00006103515625
          cy = 910.0
          output = "eDP-1"
          placement_height = 1080.0
          placement_width = 1920.0
          rotation = 0.0
          type = "login_box"

              [lockscreen_widgets.widget."lockscreen-login-box@eDP-1".settings]
              background_color = "surface_variant"
              background_opacity = 0.88
              background_radius = 12.0
              center_password_text = true
              input_opacity = 1.0
              input_radius = 0.0
              layout = "regular"
              show_caps_lock = true
              show_keyboard_layout = true
              show_login_button = true
              show_media = true
              show_session_buttons = false
              show_unlock_hint = true
              show_weather = true

          [lockscreen_widgets.widget.lockscreen-widget-0000000000000001]
          box_height = 144.0
          box_width = 272.0
          cx = 960.00006103515625
          cy = 500.0
          output = "eDP-1"
          placement_height = 1080.0
          placement_width = 1920.0
          rotation = 0.0
          type = "clock"

              [lockscreen_widgets.widget.lockscreen-widget-0000000000000001.settings]
              clock_style = "digital"
              color = "tertiary"
              format = "{:%H:%M}"

      [notification]
      layer = "overlay"

      [osd]
      position = "top_right"

          [osd.kinds]
          brightness = false
          media = false
          volume_output = false

      [shell]
      clipboard_enabled = false
      launch_apps_as_systemd_services = true
      polkit_agent = true

          [shell.animation]
          enabled = false

          [shell.panel]
          clipboard_position = "auto"
          control_center_placement = "floating"
          floating_offset = 0
          open_near_click_clipboard = true
          open_near_click_control_center = true
          polkit_position = "auto"

      [theme]
      builtin = "Nord"

      [wallpaper]
      enabled = false

          [wallpaper.default]
          path = ""

          [wallpaper.last]
          path = ""

      [widget.clock]
      format = "{:%Y-%m-%d  %H:%M}"

      [widget.control-center]
      glyph = "blend-mode"

      [widget.privacy]
      active_color = "error"
      font_scale = 2.0
      hide_inactive = true
      interactive = false

      [widget.spacer_3]
      type = "spacer"

      [widget.spacer_4]
      type = "spacer"

      [widget.spacer_5]
      type = "spacer"

      [widget.tray]
      hidden = [ "blueman" ]

      [widget.workspaces]
      hide_when_empty = true
      label_source = "name"
      labels_only_when_occupied = true
    '';

  systemd.user.packages = [
    self.packages.${pkgs.stdenv.hostPlatform.system}.clipboard-server
    self.packages.${pkgs.stdenv.hostPlatform.system}.clipboard-client
    ];

  # WARN: the server depends on wayland protocol, so it depends on graphical-session
  xdg.configFile."systemd/user/graphical-session.target.wants/clipboard-server.service".source =
    "${self.packages.${pkgs.stdenv.hostPlatform.system}.clipboard-server}/share/systemd/user/clipboard-server.service";
  xdg.configFile."systemd/user/graphical-session.target.wants/clipboard-client.service".source =
    "${self.packages.${pkgs.stdenv.hostPlatform.system}.clipboard-client}/share/systemd/user/clipboard-client.service";

  # thunar is not smart enought to mount hard disks plugged from boot
  # TODO what about nemo?
  services.udiskie.enable = true;

  xdg.autostart.enable    = true;
  xdg.autostart.entries   = [
    "${self.packages.${pkgs.stdenv.hostPlatform.system}.chillfile}/share/applications/chillfile.desktop"
    ];

  # wayland.windowManager.hyprland.extraLuaFiles.desktop_shell = ''
  wayland.windowManager.hyprland.extraConfig = ''
    hl.permission({binary="${lib.getExe pkgs.hyprpicker}", type="screencopy", mode="allow"})
    hl.permission({binary="${lib.getExe' config.programs.noctalia.package ".noctalia-wrapped"}", type="screencopy", mode="allow"})
    hl.permission({binary="${pkgs.xdg-desktop-portal-hyprland}/libexec/.xdg-desktop-portal-hyprland-wrapped", type="screencopy", mode="allow"})
    '';

  xdg.portal.enable  = true;
  xdg.portal.config = {
    common = {
      default = [ "gtk" ];
      # overrides
      # "org.freedesktop.impl.portal.Screenshot"    = [ "wlr" ];
      # "org.freedesktop.impl.portal.ScreenCast"    = [ "wlr" ];
      "org.freedesktop.impl.portal.Print"         = [ "kde" ];
      # cosmic : Access FileChooser Screenshot Settings ScreenCast
      # gtk    : Access FileChooser AppChooser Print Notification Inhibit Account Email DynamicLauncher Lockdown Settings
      # wlr    : Screenshot ScreenCast
      # xapp   : Wallpaper Inhibit Screenshot Lockdown Settings Background
      # gnome  : Access Account AppChooser Background Clipboard DynamicLauncher FileChooser GlobalShortcuts InputCapture Lockdown Notification Print RemoteDesktop ScreenCast Screenshot Settings Usb Wallpaper
      # hyprland : Screenshot ScreenCast GlobalShortcuts
      # phosh  : FileChooser Notification Settings Wallpaper
      # phrosh : Account AppChooser FileChooser Wallpaper
      # kde    : Access Account AppChooser Background Email FileChooser Inhibit Notification Print ScreenCast Screenshot RemoteDesktop Settings DynamicLauncher GlobalShortcuts InputCapture Clipboard Wallpaper Usb
      };
    # pantheon = {
    #   default = [
    #     "pantheon"
    #     "gtk"
    #   ];
    # };
    # x-cinnamon = {
    #   default = [
    #     "xapp"
    #     "gtk"
    #   ];
    # };
  };
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-gnome ]; # fallbacks
  xdg.portal.xdgOpenUsePortal = true; #BUG: xdg-open misbehaviour https://github.com/NixOS/nixpkgs/issues/160923

  # Hint Electron apps to use wayland:
#  home.sessionVariables.NIXOS_OZONE_WL =  "1";
  # Hint Java apps to use wayland:
  home.sessionVariables._JAVA_AWT_WM_NONREPARENTING = "1";

  programs.rofi.enable  = true;
  programs.rofi.extraConfig = {
    me-accept-entry         = "MousePrimary";
    me-select-entry         = "";
    hover-select            = true;
    kb-row-left             = "Left";
    kb-row-right            = "Right";
    kb-move-char-back       = "Control+b";
    kb-move-char-forward    = "Control+f";
    };

  xdg.configFile."rofi/themes/board.rasi".source = ./board.rasi;
  programs.rofi.theme = lib.mkForce "${config.xdg.configHome}/rofi/themes/board.rasi";

  systemd.user.services.wayland-pipewire-idle-inhibit = {
    Unit = {
      Description   = "Idle inhibition";
      PartOf        = "graphical-session.target";
      After         = "graphical-session.target";
      ConditionEnvironment   = "WAYLAND_DISPLAY";
      };

    Service     = {
      Type      = "simple";
      ExecStart = "${lib.getExe pkgs.wayland-pipewire-idle-inhibit}";
      Restart   = "on-failure";

      # CapabilityBoundingSet = [
      #   "~CAP_AUDIT_READ"
      #   "~CAP_AUDIT_WRITE"
      #   "~CAP_CHECKPOINT_RESTORE"
      #   "~CAP_DAC_OVERRIDE"
      #   "~CAP_DAC_READ_SEARCH"
      #   "~CAP_FOWNER"
      #   "~CAP_LINUX_IMMUTABLE"
      #   "~CAP_MAC_ADMIN"
      #   "~CAP_MAC_OVERRIDE"
      #   "~CAP_SYS_ADMIN"
      #   "~CAP_SYS_BOOT"
      #   "~CAP_SYS_CHROOT"
      #   "~CAP_SYSLOG"
      #   "~CAP_SYS_MODULE"
      #   "~CAP_SYS_RAWIO"
      #   "~CAP_SYS_RESOURCE"
      #   "~CAP_SYS_TIME"
      #   "~CAP_SYS_TTY_CONFIG"
      #   "~CAP_WAKE_ALARM"
      # ];
      # NoNewPrivileges       = "yes";
      # PrivateTmp            = "yes";
      # InaccessiblePaths     = "/boot";
      # PrivateUsers          = "yes";
      # ProtectClock          =  true;
      # ProtectControlGroups  = "yes";
      # ProtectHostname       = "yes";
      # ProtectKernelLogs     =  true;
      # ProtectKernelModules  = "yes";
      # ProtectKernelTunables = "yes";
      # # disallow writing to /usr, /bin, /sbin, ...;
      # ProtectSystem         = "yes";
      # RestrictRealtime      = "yes";
      # SystemCallFilter = [ "~@clock" "~@obsolete" "~@privileged" "~@reboot" "~@swap" ];
    };

    Install.WantedBy   = [ "graphical-session.target" ];
    };


};}
