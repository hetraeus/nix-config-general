{ flake.homeModules.media_mpd = { config, pkgs, lib, ...} : {
  home.packages = [ pkgs.mpc pkgs.euphonica ];

  home.shellAliases.mr    = " systemctl restart --user mpd #";
  home.shellAliases.mq    = " systemctl stop    --user mpd #";
  services.mpdris2.enable = true;
  services.mpd = {
  #  musicDirectory default to xdg.userDirs.music
  #  musicDirectory = /run/media/sfx/Lasagna/Music;
    enable = true;
    network.startWhenNeeded =  true; # systemd feature: only start MPD service upon connection to its socket
    extraConfig = ''
    # mpc toggle --host=$XDG_RUNTIME_DIR/mpd/socket

      auto_update  "no"
      auto_update_depth "2"
      default_permissions "read"
  #    bind_to_address    "@mpd"
      local_permissions   "read,add,control,player,admin"
     # host_permissions  "127.0.0.1 read,add,control,player,admin"

      # NOTE: MPRIS OVERRIDES THE PASSWORD !
      include "${config.sops.secrets.mpd_permissions.path}"
      include "${config.sops.secrets.mpd_soundcloud.path}"

      audio_output {
        type   "pipewire"
        name   "My PipeWire Output"
        format "48000:16:2"
      }
      audio_output {
        type         "httpd"
        name         "My HTTP Stream"
        encoder      "lame"    # optional, vorbis or lame
        port         "8000"
        #  bind_to_address  "0.0.0.0"    # optional, IPv4 or IPv6
        ##  quality    "5.0"      # do not define if bitrate is defined
        bitrate      "128"      # do not define if quality is defined
        format       "44100:16:1"
        max_clients  "0"      # optional 0=no limit
      }

      audio_output {
        type         "fifo"
        name         "my_fifo"
        # DO NOT USE $XDG_... or OTHER VARIABLE PATHS !
        path         "/tmp/mpd_fifo"
        format       "44100:16:2"
      }
    '';
    };

  wayland.windowManager.hyprland.extraConfig = let
    mpc_flags = "${lib.getExe pkgs.mpc} --host=$XDG_RUNTIME_DIR/mpd/socket --quiet ";
  in ''
    hl.bind("ALT + Z",       hl.dsp.exec_cmd("${mpc_flags} toggle"), { locked = true })
    hl.bind("ALT + less",    hl.dsp.exec_cmd("${mpc_flags}   next"), { locked = true })
    hl.bind("ALT + greater", hl.dsp.exec_cmd("${mpc_flags}   prev"), { locked = true })
    '';


};}
