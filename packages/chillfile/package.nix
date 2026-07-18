{ inputs, ... }:
{
  perSystem = { self', pkgs, lib, ... }:
    let
      wlib = inputs.wrappers.lib;

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

          extraPackages = [
            config.pkgs.kitty
            config.pkgs.edir
            config.pkgs.findutils
            config.pkgs.git
            config.pkgs.file
            config.pkgs.libnotify
            config.pkgs.wl-clipboard-rs
            config.pkgs.coreutils
            config.pkgs.bash
            self'.packages.fmenu-share
          ];

          env.FILEICON_PATH = lib.getExe self'.packages.fileicon;

          preHook = ''
            export QS_START_PATH="$HOME/my/proj"
          '';

          flags."--path" = "${qml}/share/quickshell";

          # INFO: two fixes for the WARN
          # qt.qpa.services: Failed to register with host portal QDBusError("org.freedesktop.portal.Error.Failed", "Could not register app ID: App info not found for 'org.quickshell'")
          # put also the package in profile !
          env.QS_APP_ID = "chillfile";
          patchHook = ''
            mkdir -p $out/share/applications
            cat > $out/share/applications/chillfile.desktop <<EOF
              [Desktop Entry]
              Type=Application
              Name=Chillfile
              Exec=$out/bin/chillfile
              Icon=folder
              NoDisplay=true
            EOF
            '';

          systemd = {
            description = "background file manager";
            after    = [ "multi-user-session.target" ];
            wantedBy = [ "graphical-session.target" ];
            serviceConfig = {
              ExecStart = "${config.wrapper}/bin/chillfile";
              Type = "exec";
              Restart = "on-failure";
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
