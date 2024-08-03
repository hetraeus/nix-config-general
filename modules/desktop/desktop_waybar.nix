{ flake.homeModules.desktop_waybar = { lib, config, pkgs, ...} : {

  home.packages = [ pkgs.nerd-fonts.iosevka ];
  stylix.targets.waybar.enable   = false;

  programs.waybar.enable         = true;
  programs.waybar.systemd.enable = true;


  xdg.desktopEntries.toggleWaybar = {
    name        = "Toggle waybar panel hide show";
    exec        = "${lib.getExe' pkgs.procps "pkill"} -USR1 waybar";
    terminal    = false;
    icon        = "slidewall";
    };

  programs.waybar.settings.mainBar = {
    position  =  "bottom";
    layer     =     "top";
    exclusive =     false;
    # height           = 2;
    # margin-top       = 0;
    # margin-bottom    = 0;
    margin-right   = 0;
    margin-left    = 1600;
  #  modules-left   = [ ];
  # modules-center = [ "hyprland/submap" ];
    modules-right  = [ "privacy" "tray" "custom/notitoggler" ];

    # "custom/paneltoggler" = {
    #   format = "◀";
    #   on-click = "pkill -SIGUSR1 -f \"waybar --config $XDG_CONFIG_HOME/waybar/config.json\""
    # };
    "privacy" = {
      icon-spacing =  3;
      icon-size    = 16;
      transition-duration = 0;
      modules = [
        { tooltip-icon-size = 24; tooltip = true; type = "screenshare"; }
        { tooltip-icon-size = 24; tooltip = true; type =   "audio-out"; }
        { tooltip-icon-size = 24; tooltip = true; type =    "audio-in"; }
        ];};
    "tray"    = {
      spacing = 5;
      };
    "custom/notitoggler" = {
      format       = "󰎟";
      icon-spacing =  3;
      icon-size    =  25;
      on-click = "${lib.getExe' pkgs.swaynotificationcenter "swaync-client"} --toggle-panel";
      };
  };


  programs.waybar.style = ''
  * {
    border: none;
    border-radius: 0rem;
    font-family: ${config.stylix.fonts.monospace.name};
    /*font-size: 1.1rem;*/
    font-style: normal;
    min-height: 0;
  }

  window#waybar {
    color: #f4d9e1;
    background-color: transparent;
    margin-left: 0rem;
    margin-right: 0rem;
    padding-left: 0rem;
    padding-right: 0rem;
  }

  #workspaces {
    margin: 0rem 0rem 0rem 0rem;
    padding: 0rem 5px 0rem 5px;
    font-weight: normal;
    font-style: normal;
  }
  #workspaces button {
    padding: 0rem 0.1rem;
    border-radius: 16px;
    color: #928374;
  }

  #workspaces button.active {
    color: #f4d9e1;
    background: rgba(30, 30, 46, 0.5);
    border-radius: 16px;
  }

  #workspaces button:hover {
    background-color: #e6b9c6;
    color: black;
    border-radius: 0.3rem;
  }

  #custom-toggler {
    font-size: 0.8rem;
  }
  #custom-date,
  #clock,
  #battery,
  #wireplumber,
  #network {
    margin: 0rem 0rem 0rem 0rem;
    border-radius: 8px;
    border: solid 0rem #f4d9e1;
  }

  #custom-date {
    color: #d3869b;
  }

  #custom-power {
    color: #24283b;
    background-color: #db4b4b;
    border-radius: 5px;
    margin-right: 10px;
    margin-top: 0rem;
    margin-bottom: 0rem;
    margin-left: 0rem;
    padding: 0rem 0rem;
  }

  #custom-notitoggler,
  #privacy,
  #tray {
    background: rgba(30, 28, 50, 0.9);
    border-top: 0.15rem solid ${config.lib.stylix.colors.withHashtag.base0D};
    margin: 0rem 0rem 0rem 0rem;
    padding: 0rem 0.8rem 0rem 0.8rem;
  }

  #submap{
    background: rgba(30, 28, 50, 0.9);
    border-top: 0.15rem solid ${config.lib.stylix.colors.withHashtag.base08};
    margin: 0rem 0rem 0rem 0rem;
    padding: 0rem 2.8rem 0rem 2.8rem;
    font-family: "${config.stylix.fonts.sansSerif.name}";
  }

  #privacy-item.audio-in {
    color: ${config.lib.stylix.colors.withHashtag.base08};
  }

  #clock {
    color: #e6b9c6;
    padding-left: 0.5rem;
    padding-right: 0.5rem;
    margin-right: 0rem;
    margin-left: 10px;
    margin-top: 0rem;
    margin-bottom: 0rem;
    font-weight: bold;
  }

  #battery {
    color: #199ca8;
  }

  #battery.charging {
    color: #199ca8;
  }

  #battery.warning:not(.charging) {
    background-color: #f7768e;
    color: #24283b;
    border-radius: 5px 5px 5px 5px;
  }

  #backlight {
    color: #f4d9e1;
    border-radius: 0rem 0rem 0rem 0rem;
    margin: 0rem;
    margin-left: 0rem;
    margin-right: 0rem;
    padding-left: 0.5rem;
  }

  #network {
    color: #f4d9e1;
    padding-left: 0.5rem;
    padding-right: 0.5rem;
    border-radius: 8px;
    margin-right: 5px;
  }

  #wireplumber {
    color: #f4d9e1;
    padding-left: 0.5rem;
    padding-right: 0.5rem;
  }

  #wireplumber.muted {
    color: #928374;
    border-radius: 8px;
    margin-left: 0rem;
  }

  #custom-launcher {
    color: #e5809e;
    background: rgba(30, 30, 46, 0.5);
    border-radius: 0rem 24px 0rem 0rem;
    margin: 0rem 0rem 0rem 0rem;
    padding: 0 20px 0 13px;
    font-size: 20px;
  }

  #custom-launcher button:hover {
    background-color: #fb4934;
    color: transparent;
    border-radius: 8px;
    margin-right: -5px;
    margin-left: 10px;
  }

  #window {
    margin-left: 0rem;
    margin-right: 0rem;
    padding-left: 0rem;
    padding-right: 0rem;
    border-radius: 0rem;
    margin-top: 0rem;
    margin-bottom: 0rem;
    font-weight: bold;
    font-style: normal;
    font-size: 0.9rem;
    color: ${config.lib.stylix.colors.withHashtag.base00};
    background-color: transparent;
  }
    '';
};}
