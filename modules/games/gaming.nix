{ flake.nixosModules.gaming = { pkgs, lib, ... }: {
  boot.kernelModules = [ "ntsync" ];
  programs.gamemode.enable = true;

  services.opensnitch.rules.dny_ruffle = {
    name        = "dny_ruffle";
    created     = "2018-04-07T14:13:27.903996051+02:00"; # silence logs
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
    created     = "2018-04-07T14:13:27.903996051+02:00"; # silence logs
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

flake.homeModules.gaming = { pkgs, lib, self, ... }: {
  home.packages = [
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

  # programs.retroarch.enable = true;
  # programs.retroarch.cores  = {
  #   melonds.enable          = true;
  #   mgba.enable             = true;
  #   fuse.enable             = true;
  #   mame2003-plus.enable    = true;
  #   };
  # programs.retroarch.settings = {
  #   # https://github.com/libretro/RetroArch/blob/master/retroarch.cfg
  #   menu_show_load_content_animation = "false";
  #   input_exit_emulator = "";
  #   audio_driver        = "pipewire";
  #   camera_driver       = "pipewire";
  #   video_driver        = "vulkan";
  #   video_shader_enable = "true";
  #   video_shader_dir    = "${pkgs.libretro-shaders-slang}/share/libretro/shaders";
  #   };

  # xdg.configFile."retroarch/config/retroarch.slangp".text = ''
  #   #reference "${pkgs.libretro-shaders-slang}/share/libretro/shaders/shaders_slang/edge-smoothing/ddt/ddt-extended.slangp"
  #   '';

    #reference "/nix/store/w817mvykhzw17xylsfi5qy21qh9f0jy2-libretro-shaders-slang-0-unstable-2025-12-27/share/libretro/shaders/shaders_slang/edge-smoothing/ddt/ddt-extended.slangp"
};}
