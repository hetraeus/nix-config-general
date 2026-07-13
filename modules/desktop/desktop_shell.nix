{ flake.nixosModules.desktop_shell = { pkgs, lib, ... }: {

  environment.systemPackages = [
    pkgs.brightnessctl
    pkgs.wlr-randr
    ];

  security.polkit.enable = true; # allow nix shell 'nixpkgs#gparted' --command gparted
  # Realtime scheduling priority to user processes on demand
  security.rtkit.enable    = true;

  # GTK+ applications configuration, needed by home-manager > easyeffect
  programs.dconf.enable    = true;

  environment.pathsToLink = [ "/share/xdg-desktop-portal" "/share/applications" ]; # allow portals in home manager
  programs.appimage = {
    enable = true;
    binfmt = true;
    package = pkgs.appimage-run.override {
     extraPkgs = pkgs: [
        pkgs.icu
        ];
      };
    };
  services.flatpak.package = true; # 2025-07-20 beekeeper can't be installed with nix https://github.com/beekeeper-studio/beekeeper-studio/pull/3023

  # mount
  services.gvfs.enable     = true;
  services.udisks2.enable  = true; # needed by udiskie
  services.tumbler.enable  = true;
  programs.xfconf.enable   = true;
  programs.thunar.enable   = true;
  programs.thunar.plugins = with pkgs; [ thunar-archive-plugin thunar-volman thunar-vcs-plugin thunar-shares-plugin thunar-media-tags-plugin ];

  # Should withelist wttr.in , but sometimes is not online. Can I replace it?

  services.opensnitch.rules.flk-flatpak = {
    name        = "flk-flatpak";
    created     = "2018-04-07T14:13:27.903996051+02:00"; # silence logs
    enabled     = true;
    action      = "allow";
    duration    = "always";
    operator    = {
      type      = "list";
      operand   = "list";
      sensitive = false;
      list      = [{
       type     = "simple";
       operand  = "process.command";
       data     = "${lib.getExe' pkgs.flatpak ".flatpak-wrapped"}";
       } {
       type     = "regexp";
       operand  = "dest.host";
       data     = "^(ciscobinary\.openh264\.org|dl\.flathub\.org)$";
       } {
       type     = "simple";
       operand  = "dest.port";
       data     = "443";
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
  #  pkgs.wlr-which-key
    pkgs.glib # allow gio trash, gio rm and other xdg desktop aware commands
    pkgs.playerctl

    pkgs.flatpak
    pkgs.zbar
    pkgs.zint-qt
    ];

  systemd.user.packages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.chillfile ];
  systemd.user.services.chillfile.wantedBy = [ "graphical-session.target" ];
  services.udiskie.enable = true; # thunar is not smart enought to mount hard disks plugged from boot
  xdg.autostart.enable = true;
  xdg.autostart.entries = lib.singleton ( # TEST
    pkgs.makeDesktopItem {
      name = "password dialog";
      desktopName = "password dialog";
      exec = "${lib.getExe' pkgs.lxqt.lxqt-policykit "lxqt-policykit-agent"}";
      } + /share/applications/password_dialog.desktop
    );

  # BUG: https://github.com/gmodena/nix-flatpak/issues/31
  # Hide warning about showing the program in the menu
  xdg.systemDirs.data  = [ "${config.xdg.dataHome}/flatpak/exports/share" ];

  services.copyq.enable        = true;
  systemd.user.services.copyq.Service.Environment = lib.mkForce [ "QT_QPA_PLATFORM=wayland" ]; # TODO: remove this line
  services.copyq.package = let
    # BUG: https://github.com/hluk/CopyQ/issues/3108
    pkgs_pinned_1 = import (fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/e6f23dc08d3624daab7094b701aa3954923c6bbb.tar.gz";
      sha256 = "0m0xmk8sjb5gv2pq7s8w7qxf7qggqsd3rxzv3xrqkhfimy2x7bnx";
      }) { system = pkgs.stdenv.hostPlatform.system; };
    in pkgs_pinned_1.copyq;

  # wayland.windowManager.hyprland.extraLuaFiles.desktop_shell = ''
  wayland.windowManager.hyprland.extraConfig = ''
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

  systemd.user.services.sway-audio-idle-inhibit = {
    Unit = {
      Description   = "Idle inhibition";
      Documentation = "https://github.com/ErikReider/SwayAudioIdleInhibit";
      PartOf        = "graphical-session.target";
      After         = "graphical-session.target";
      ConditionEnvironment   = "WAYLAND_DISPLAY";
      };

    Service     = {
      Type      = "simple";
      ExecStart = "${lib.getExe pkgs.sway-audio-idle-inhibit}";
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
