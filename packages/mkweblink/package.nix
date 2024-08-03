{ perSystem = { pkgs, ... }: {
  packages.mkweblink = pkgs.writeShellApplication {
    name               = "mkweblink";
    excludeShellChecks = [ "SC1091" ];
    runtimeInputs      = [ pkgs.gnused pkgs.libnotify pkgs.coreutils ];
    text = ''
      [[ -z $1 ]] && { notify-send "$0" "missing argument"; exit; }
      WEBSITE_NAME=$(cut --delimiter "/" --field 3 <<< "$1").html
      source "''${XDG_CONFIG_HOME:-.config}/user-dirs.dirs"
      sed "s/url=/url=\"$(printf '%s' "''${1:-invalidpath}")\"/" "$XDG_TEMPLATES_DIR/weblink.html" > "$WEBSITE_NAME"
    '';
  };
};}
