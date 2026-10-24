{ flake.nixosModules.media_navidrome = { config, pkgs, lib, ...} : {

  assertions = [
    { assertion = (config.services.navidrome.settings.MusicFolder or null) != null;
      message = "services.navidrome.settings.MusicFolder must be set (e.g. \"/srv/music\").";
    }
    ];
  services.navidrome.enable = true;
  services.navidrome.openFirewall = true;
  
};
flake.homeModules.media_navidrome = { config, pkgs, lib, ...} : {
  home.packages = [ pkgs.cliamp ]; # TODO pkgs.smyx ];
  # home.shellAliases.mr    = " systemctl restart --user mpd #";
  # home.shellAliases.mq    = " systemctl stop    --user mpd #";
  # services.mpdris2-rs.enable = true;
  # wayland.windowManager.hyprland.extraConfig = let
  #   mpc_flags = "${lib.getExe pkgs.mpc} --host=$XDG_RUNTIME_DIR/mpd/socket --quiet ";
  # in ''
  #   hl.bind("ALT + Z",       hl.dsp.exec_cmd("${mpc_flags} toggle"), { locked = true })
  #   hl.bind("ALT + less",    hl.dsp.exec_cmd("${mpc_flags}   next"), { locked = true })
  #   hl.bind("ALT + greater", hl.dsp.exec_cmd("${mpc_flags}   prev"), { locked = true })
  #   '';

};}
