{ perSystem = { self', pkgs, lib, ... }: {
  packages.chillfile = let

    script = pkgs.stdenv.mkDerivation {
      pname = "chillfile";
      version = "0.1.0";
      src = ./.;

      nativeBuildInputs = [ pkgs.makeWrapper ];
      buildInputs = [
        pkgs.kitty
        pkgs.edir
        pkgs.findutils
        pkgs.git
        pkgs.file
        pkgs.wl-clipboard-rs
        self'.packages.fmenu-share
        ];

      installPhase = ''
        runHook preInstall

        mkdir -p $out/share/quickshell
        cp -r qml/* $out/share/quickshell/

        # Install the launcher script
        mkdir -p $out/bin
        makeWrapper ${lib.getExe pkgs.quickshell} $out/bin/chillfile \
          --run 'export QS_START_PATH="$HOME/my/proj"' \
          --set FILEICON_PATH "${lib.getExe self'.packages.fileicon}" \
          --add-flags "--path $out/share/quickshell"

        runHook postInstall
      '';

      meta = with lib; {
        description = "quickshell background layer file manager";
        license = licenses.lgpl21Only;
        platforms = platforms.linux;
      };

    };

  in pkgs.symlinkJoin {
    name = "chillfile-wrapper";
    meta.mainProgram = "chillfile";
    paths = [ script ];
    postBuild = ''
      mkdir -p $out/share/systemd/user
      cat > $out/share/systemd/user/chillfile.service <<EOF
[Service]
ExecStart=chillfile
Type=exec
PrivateTmp=yes

[Unit]
After=multi-user-session.target
Description=background file manager

[Install]
WantedBy=graphical-session.target
EOF
'';};

};}
