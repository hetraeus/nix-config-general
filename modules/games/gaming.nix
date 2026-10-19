{ flake.nixosModules.gaming = { pkgs, lib, ... }: {
  boot.kernelModules = [ "ntsync" ];
  programs.gamemode.enable = true;

  services.opensnitch.rules.dny_ruffle = {
    name        = "dny_ruffle";
    created     = "2010-01-01T10:00:00.000000Z"; # silence logs
    enabled     = true;
    action      = "deny";
    duration    = "always";
    operator    = {
      type      = "list";
      operand   = "list";
      sensitive = false;
      list      = [{
       type     = "simple";
       operand  = "process.command";
       data     = "${lib.getExe pkgs.ruffle}";
       }];
    };};

  services.opensnitch.rules.ggg_mindustry = {
    name        = "ggg_mindustry";
    created     = "2010-01-01T10:00:00.000000Z"; # silence logs
    enabled     = true;
    action      = "allow";
    duration    = "always";
    operator    = {
      type      = "list";
      operand   = "list";
      sensitive = false;
      list      = [{
       type     = "regexp";
       operand  = "process.command";
       data     = "/nix/store/.*-openjdk-.*/bin/java -jar ${pkgs.mindustry}/share/mindustry.jar";
       } {
       type     = "simple";
       operand  = "dest.host";
       data     = "raw.githubusercontent.com";
       } {
       type     = "simple";
       operand  = "dest.port";
       data     = "443";
       }];
    };};
};

flake.homeModules.gaming = { pkgs, lib, self, config, ... }: {


  multiverse.config.allowUnfree = true;
  multiverse.pins = {
    ut1999 = "469e";
    ut2004 = "3374-preview-23";
    };
  home.packages = [
    config.multiverse.pinned.ut1999
    config.multiverse.pinned.ut2004

  #  fmenu-games-roms

    pkgs.flare
    pkgs.lbreakouthd
    pkgs.pioneers
    pkgs.sgt-puzzles
    pkgs.space-cadet-pinball
  # pkgs.superTuxKart
    pkgs.tetris
    pkgs.wesnoth
    pkgs.mindustry
    pkgs.openloco

  #  manga-tui
    pkgs.faugus-launcher
    self.packages.${pkgs.stdenv.hostPlatform.system}.retroarch-ready
    ];

  xdg.desktopEntries.sudoku = {
    name         = "sudoku";
    genericName  = "puzzle solitaire";
    icon         = "ksudoku";
    terminal     = false;
    categories   = [ "Game" ];
    exec         = "${lib.getExe' pkgs.sgt-puzzles "solo"}";
    };
  home.file.".utpg/System/UnrealTournament.ini".source = ./UnrealTournament.ini;
  home.file.".utpg/System/User.ini".source             = ./User.ini;

  wayland.windowManager.hyprland.settings.window_rule = [{
   match.class = "^(ut-bin-.*)$";
   border_size = 0;
   }];

};}
