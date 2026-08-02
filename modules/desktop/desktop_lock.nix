{ flake.homeModules.desktop_lock = { pkgs, lib, config, ... }: let
  lock = "${lib.getExe' pkgs.procps "pidof"} hyprlock || ${lib.getExe config.programs.hyprlock.package}";

  dpms_ctrl = status : pkgs.writeShellApplication {
    name = "dpms_ctrl";
    text = ''
      hyprctl dispatch 'hl.dsp.dpms({ action = "${status}" })'
      '';
  };
in {

  home.packages = [ (dpms_ctrl "toggle") ]; # needed by kdeconnect

  programs.hyprlock.enable = true;
  services.hypridle.enable = true;
  services.hypridle.settings.general = {
    #lock_cmd = pidof hyprlock || find $XDG_RUNTIME_DIR -iname hyprlock_override | grep --quiet hyprlock_override && hyprlock
#    unlock_cmd          = "${lib.getExe' pkgs.systemd   "loginctl"   } unlock-session";
    lock_cmd            = lock;
    before_sleep_cmd    = "${lib.getExe' pkgs.libnotify "notify-send"} --app-name=hypridle 'Zzz'";
    after_sleep_cmd     = "${lib.getExe (dpms_ctrl  "on")}; ${lib.getExe' pkgs.libnotify "notify-send"} --app-name=hypridle '⯕  Awake!'";
    ignore_dbus_inhibit = false; # dbus-sent idle-inhibit requests used by e.g. firefox or steam
    };

  services.hypridle.settings.listener = let
    minute = 60;
    lock_timeout = 8;
    susp_timeout = 30;
    grace  = 10;

    in [
    { timeout = lock_timeout * minute - grace;
       on-timeout = "${lib.getExe (dpms_ctrl "off")}";
       on-resume  = "${lib.getExe (dpms_ctrl  "on")}";
       }

    { timeout = lock_timeout * minute;
      on-timeout = lock;
      }

    # suspend pc after 30min
    { timeout = susp_timeout*minute;
       on-timeout = "${lib.getExe' pkgs.systemd "systemctl"} suspend";
       }

    ];

  # wayland.windowManager.hyprland.extraLuaFiles.hyprlock_integration = ''
  wayland.windowManager.hyprland.extraConfig = ''
    hl.permission({binary="${lib.getExe config.programs.hyprlock.package}", type="screencopy", mode="allow"})
    '';

};}
