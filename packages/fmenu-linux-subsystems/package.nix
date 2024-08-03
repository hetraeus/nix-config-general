{ perSystem = { pkgs, lib, ... }: {
  packages.fmenu-linux-subsystems = let
    script = pkgs.writeShellApplication {
      name          = "fmenu-linux-subsystems";
      runtimeInputs = [ pkgs.linux-doc pkgs.xdg-utils ];
      text = ''
        ${lib.getExe' pkgs.xdg-utils "xdg-open"} ${pkgs.linux-doc}/share/doc/linux-doc/admin-guide/abi-stable.html
        ${lib.getExe' pkgs.xdg-utils "xdg-open"} ${pkgs.linux-doc}/share/doc/linux-doc/admin-guide/abi-testing.html
      '';
    };
    desktopItem = pkgs.makeDesktopItem {
      exec        = "fmenu-linux-subsystems";
      name        = "Linux kernel subsystems";
      genericName = "/sys /run blocks";
      desktopName = "API ABI documentation";
      categories  = [ "Utility" ];
      icon        = "supertux";
    };
  in pkgs.buildEnv {
    name  = "fmenu-linux-subsystem-wrapper";
    paths = [ script desktopItem ];
    meta.mainProgram = "fmenu-linux-subsystem";
  };
};}
