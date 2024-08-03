{ flake.homeModules.observability_dashboard = { pkgs, lib, self, ...} : let
  fmenu-allfeeds       = self.packages.${pkgs.stdenv.hostPlatform.system}.fmenu-allfeeds;
  fmenu-journal-follow = self.packages.${pkgs.stdenv.hostPlatform.system}.fmenu-journal-follow;
  fmenu-alltop         = self.packages.${pkgs.stdenv.hostPlatform.system}.fmenu-alltop;
  fmenu-powerprofiles  = self.packages.${pkgs.stdenv.hostPlatform.system}.fmenu-powerprofiles;
in {

  home.packages = [ pkgs.kitty pkgs.isd fmenu-journal-follow fmenu-powerprofiles pkgs.witr pkgs.nuclei ];
  systemd.user.packages = [ fmenu-allfeeds ];
  systemd.user.timers.fmenu-allfeeds.Install.WantedBy = [ "timers.target" ];

  systemd.user.services.log_dashboard = let
    log_kitty_session = pkgs.writeText "log_kitty_session" ''
      enabled_layouts tall:full_size=1;bias=28,fat:bias=22;full_size=1;mirrored=true,stack
      launch sh -c "while true; do ${lib.getExe fmenu-alltop         }; done"
      launch sh -c "while true; do ${lib.getExe fmenu-allfeeds       }; done"
      launch sh -c "while true; do ${lib.getExe fmenu-journal-follow }; done"
      launch kitty @ focus-window --match=cmdline:journal_follow
      '';
  in {
    Service.ExecStart = "${lib.getExe pkgs.kitty} --app-id='log_dashboard' --title='🪷 controls' --session=${log_kitty_session}";
    Unit.Description  = "log_dashboard";
    Unit.After        = [ "graphical-session.target" ] ;
    Unit.Wants        = [ "graphical-session.target" ] ;
    Install.WantedBy  = [ "graphical-session.target" ] ;
    };
};}
