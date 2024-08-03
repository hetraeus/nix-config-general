{ flake.homeModules.desktop_notification = { pkgs, lib, config, self, ... }: let
  visual_caffeine_get = self.packages.${pkgs.stdenv.hostPlatform.system}.visual-caffeine-get;
  visual_caffeine     = self.packages.${pkgs.stdenv.hostPlatform.system}.visual-caffeine;
  pink_noise          = self.packages.${pkgs.stdenv.hostPlatform.system}.pink-noise;

in  {

xdg.desktopEntries.swaync = {
  exec = "${lib.getExe' pkgs.swaynotificationcenter "swaync-client"} --toggle-panel";
  name = "Notification History log swaync";
  type                    = "Application" ;
  settings.Keywords       = "messages"    ;
  icon       = "notification-new-symbolic";
  };

services.swaync.enable   = true;
services.swaync.settings = {
#  "$schema": "/etc/xdg/swaync/configSchema.json";
  control-center-height          = 1063;
  control-center-layer           = "top";
  control-center-margin-bottom   = 10;
  control-center-margin-left     = 0;
  control-center-margin-right    = 10;
  control-center-margin-top      = 10;
  control-center-width           = 500;
  cssPriority                    = "application";
  fit-to-screen                  = true;
  hide-on-action                 = true;
  hide-on-clear                  = false;
  image-visibility               = "when-available";
  keyboard-shortcuts             = true;
  layer                          = "overlay";
  layer-shell                    = true;
  notification-2fa-action        = true;
  notification-body-image-height = 100;
  notification-body-image-width  = 200;
  notification-icon-size         = 64;
  notification-inline-replies    = true;
  notification-window-width      = 500;
  positionX                      = "right";
  positionY                      = "top";
  relative-timestamps            = true;
  script-fail-notify             = true;
  timeout                        = 10;
  timeout-critical               = 0;
  timeout-low                    = 5;
  transition-time                = 100;
  widgets = [
    "notifications"
    "inhibitors"
    "mpris"
    "backlight"
    "volume"
    "buttons-grid"
    ];
  };

services.swaync.settings.widget-config  = {
  inhibitors   = { text = "Inhibitors";    clear-all-button = true; button-text = "Clear All"; };
  title        = { text = "Notifications"; clear-all-button = true; button-text = "󰆴";         };
  dnd          = { text = "do not disturb"; };
  label        = { text = "Notification Center"; max-lines = 1; };
  mpris        = { image-size = 96;           image-radius = 7; };
  volume       = { label = "󰕾 "; };
  backlight    = { label = "󰃟 "; };
  };
services.swaync.settings.widget-config.buttons-grid.actions = [ {
  label          = "󰕾";
  type           = "toggle";
  active         = true;
  command        = pkgs.writeShellScript "swaync_volume_cmd" "${lib.getExe' pkgs.wireplumber "wpctl"} set-mute @DEFAULT_AUDIO_SINK@   toggle";
  update-command = pkgs.writeShellScript "swaync_volume_up"  "sh -c 'if ${lib.getExe' pkgs.wireplumber "wpctl"} get-volume @DEFAULT_AUDIO_SINK@ | ${lib.getExe pkgs.gnugrep} --quiet '[MUTED]'; then echo false; else echo true; fi'";
  } {
  label          = "󰍬";
  type           = "toggle";
  active         = true;
  command        = pkgs.writeShellScript "swaync_mic_cmd" "${lib.getExe' pkgs.wireplumber "wpctl"} set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
  update-command = pkgs.writeShellScript "swaync_mic_up"  "sh -c 'if ${lib.getExe' pkgs.wireplumber "wpctl"} get-volume @DEFAULT_AUDIO_SOURCE@ | ${lib.getExe pkgs.gnugrep} --quiet '[MUTED]'; then echo false; else echo true; fi'";
  } {
  label          = "󰂛";
  type           = "toggle";
  active         = false;
  command        = "${lib.getExe' config.services.swaync.package "swaync-client"} --toggle-dnd";
  update-command = "${lib.getExe' config.services.swaync.package "swaync-client"}    --get-dnd";
  } {
  label          = "󱗺";
  type           = "toggle";
  active         = false;
  command        = pkgs.writeShellScript "swaync_pink_cmd" "sh -c '${lib.getExe pink_noise}'";
  update-command = pkgs.writeShellScript "swaync_pink_up"  "sh -c '${lib.getExe' pkgs.procps "pgrep"} --full synth\\ pinknoise\\ band && echo true || echo false'";
  } {
  label          = "󰂯";
  command        = "${lib.getExe' pkgs.blueman "blueman-manager"}";
  } {
  label          = "󰌾";
  command        = if config.programs.hyprlock.enable then "${lib.getExe config.programs.hyprlock.package}" else "${lib.getExe' pkgs.systemd "loginctl"} lock-session";

  } {
  label          = "";
  type           = "toggle";
  active         = false;
  command        = "${lib.getExe visual_caffeine}";
  update-command = "${lib.getExe visual_caffeine_get}";

  } ];

};}
