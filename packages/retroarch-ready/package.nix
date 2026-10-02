{ lib, inputs, ... }: {
  perSystem = { pkgs, ... }: {
    packages.retroarch-ready = let
      retroarchWrapped = pkgs.retroarch.withCores (cores: with cores; [
        mame2003-plus
        melondsds # Nintendo DS
        mgba # Gameboy + Gameboy Advance
        bsnes-hd # Super Nintando
        flycast # SEGA Dreamcast, Naomi, Naomi 2, Atomiswave
        fuse # Sinclair spectrum
        beetle-psx-hw # Playstation 1
        play # Playstation 2
      ]);

      retroarchCfg = let
        readDirRecursive = dir:
          dir
          |> lib.filesystem.listFilesRecursive
          |> map builtins.readFile
          |> lib.concatStringsSep "\n";
      in pkgs.writeText "retroarch.cfg" ''
        ${readDirRecursive ./config}
        assets_directory = "${pkgs.retroarch-assets}/share/retroarch/assets"
        video_shader_dir = "${pkgs.libretro-shaders-slang}/share/libretro/shaders"
        joypad_autoconfig_dir = "${pkgs.retroarch-joypad-autoconfig}/share/libretro/autoconfig"
      '';

    in
    inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = retroarchWrapped;
      
      flagSeparator = "=";
      flags = {
        "--set-shader" = "${pkgs.libretro-shaders-slang}/share/libretro/shaders/shaders_slang/edge-smoothing/ddt/ddt-extended.slangp";
        "--config" = retroarchCfg;
      };
    };
  };
}
