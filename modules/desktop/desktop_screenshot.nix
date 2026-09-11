{ inputs, ... }: { flake.homeModules.desktop_screenshot =
  { pkgs, lib, config, self, ... }: let
    ocr-screen = self.packages.${pkgs.stdenv.hostPlatform.system}.ocr-screen;
    omasnap = inputs.omasnap-nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.omasnap;

  in {
    home.packages = [ ocr-screen omasnap ];

    programs.hyprshot.saveLocation =
      "${config.xdg.userDirs.pictures}/.private/shots";

    xdg.userDirs.extraConfig.SCREENSHOTS =
      "${config.programs.hyprshot.saveLocation}";

    xdg.desktopEntries.screenshots_dir = {
      name = "Screenshot Directory";
      exec =
        "${lib.getExe' pkgs.xdg-utils "xdg-open"} \"${config.xdg.userDirs.extraConfig.SCREENSHOTS}\"";
      terminal = false;
      categories = [ "Utility" ];
      genericName = "screenshot folder";
      icon = "gtk-directory";
    };

    wayland.windowManager.hyprland.extraConfig = ''
      hl.layer_rule({ match = { namespace = "^(omasnap)$" }, no_anim = true })

      hl.permission({
        binary="${omasnap}/bin/.omasnap-wrapped",
        type="screencopy",
        mode="allow"
      })
      hl.permission({
        binary="${lib.getExe pkgs.grim}",
        type="screencopy",
        mode="allow"
      })
      hl.permission({
        binary="${lib.getExe inputs.omasnap-nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.grim}",
        type="screencopy",
        mode="allow"
      })
      hl.bind("Print", hl.dsp.exec_cmd("${lib.getExe omasnap}"))
      hl.bind("SHIFT + Print", hl.dsp.exec_cmd("${lib.getExe ocr-screen}"))
    '';
  };
}
