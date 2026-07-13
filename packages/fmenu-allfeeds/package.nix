{ perSystem = { pkgs, lib, ... }: let
  script = let
    feed-wrap = pkgs.writeShellApplication {
      name          = "feed-wrap";
      runtimeInputs = [ pkgs.reader pkgs.gum ];
      text          = ''
        reader --image-mode kitty "$@" \
        | gum pager --border="none" --show-line-numbers=false
      '';
    };
  in pkgs.writeShellApplication {
    name          = "fmenu-allfeeds";
    runtimeInputs = [ pkgs.coreutils pkgs.sfeed ];
    text          = ''
      stty -echoctl
      trap true SIGINT
      FEEDS_DIR="$HOME/.cache/sfeed/feeds_it"
      [ ! -d "$FEEDS_DIR" ] && mkdir --parents "$FEEDS_DIR"
      set +o errexit
      while true; do
        timeout --foreground 30m \
          env SFEED_PLUMBER="${lib.getExe feed-wrap}" SFEED_PLUMBER_INTERACTIVE=1 sfeed_curses "$FEEDS_DIR"/*
      done
    '';};
  in {

  packages.fmenu-allfeeds = pkgs.symlinkJoin {
    name = "fmenu-allfeeds";
    meta.mainProgram = "fmenu-allfeeds";
    paths = [ script ];
    postBuild = let
      sfeedDeps = with pkgs; [ sfeed coreutils curl findutils glibc ];
     in ''
      mkdir -p $out/share/systemd/user
      cat > $out/share/systemd/user/fmenu-allfeeds.service <<EOF
[Service]
ExecStart=${lib.getExe' pkgs.sfeed "sfeed_update"} %h/.local/config/sfeed_it
Type=exec
PrivateTmp=yes
Environment="PATH=${lib.makeBinPath sfeedDeps}"

[Unit]
After=multi-user-session.target
Description=fmenu-allfeeds
EOF
'';};

};}
