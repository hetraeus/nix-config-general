{ perSystem = { self', pkgs, lib, inputs, ... }:
  let
    wlib = inputs.wrappers.lib;

    # just the qml assets, nothing else
    qml = pkgs.stdenv.mkDerivation {
      pname = "chillfile-qml";
      version = "0.1.0";
      src = ./.;
      installPhase = ''
        runHook preInstall
        mkdir -p $out/share/quickshell
        cp -r qml/* $out/share/quickshell/
        runHook postInstall
      '';
    };

    chillfile = (wlib.wrapModule ({ config, wlib, ... }: {
      imports = [ wlib.modules.systemd ];
      config = {
        package = config.pkgs.quickshell;
        binName = "chillfile";

        runtimeInputs = [
          config.pkgs.kitty
          config.pkgs.edir
          config.pkgs.findutils
          config.pkgs.git
          config.pkgs.file
          config.pkgs.wl-clipboard-rs
          self'.packages.fmenu-share
        ];

        env.FILEICON_PATH = lib.getExe self'.packages.fileicon;

        preHook = ''
          export QS_START_PATH="$HOME/my/proj"
        '';

        flags."--path" = "${qml}/share/quickshell";

        systemd = {
          description = "background file manager";
          after = [ "multi-user-session.target" ];
          wantedBy = [ "graphical-session.target" ];
          serviceConfig = {
            Type = "exec";
            PrivateTmp = true;
          };
        };
      };
    })).apply { pkgs = pkgs; };
  in {
    packages.chillfile = chillfile.wrapper;
    packages.chillfile-systemd-user = chillfile.outputs.systemd-user;
  };
}
