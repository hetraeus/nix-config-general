{ perSystem = { pkgs, lib, ... }: {
  packages.qr-code-connect = let

    script = pkgs.writeShellApplication {
      name          = "qr-code-connect";
      runtimeInputs = [ pkgs.fzf pkgs.iwd pkgs.gnused pkgs.coreutils pkgs.iproute2 ];
      text = builtins.readFile ./qr-code-connect ;
      };

  desktopItem = pkgs.makeDesktopItem {
    name         = "qr-code-connect";
    genericName  = "qr-code-connect";
    desktopName  = "QR code connect wifi network";
    icon         = "qr-code-symbolic";
    terminal     = false;
    categories   = [ "Network" ];
    exec         = "${lib.getExe pkgs.kitty} ${lib.getExe script}";
    };

  in pkgs.buildEnv {
    name             = "qr-code-connect";
    paths            = [ script desktopItem ];
    meta.mainProgram = "qr-code-connect";
  };

};}
