{ perSystem = { pkgs, ... }: {
  packages.hyprnotipick = let
    script = pkgs.writeShellApplication {
      name          = "hyprnotipick";
      text          = builtins.readFile ./hyprnotipick;
      runtimeInputs = [ pkgs.wl-clipboard-rs pkgs.libnotify pkgs.hyprpicker ];
    };
    desktopItem = pkgs.makeDesktopItem {
      name        = "hyprnotipick";
      exec        = "hyprnotipick";
      desktopName = "hyprnotipick";
      genericName = "color picker rgb hex display screen pixel";
      categories  = [ "Utility" ];
      icon        = "gtk-color-picker";
    };
  in pkgs.buildEnv {
    name             = "hyprnotipick-wrapper";
    paths            = [ script desktopItem ];
    meta.mainProgram = "hyprnotipick";
  };
};}
