{ perSystem = { pkgs, ... }: {
  packages.url-unshorten = let
    script = pkgs.writeShellApplication {
    name          = "url-unshorten";
    runtimeInputs = [ pkgs.libnotify pkgs.curl pkgs.wl-clipboard-rs pkgs.gnused ];
    text = ''
      OBF_URL="''${*:-$(wl-paste)}"
      ACTUAL_URL="$(curl --silent --head --location "$OBF_URL" \
      | sed --silent     's/^[Ll]ocation: *//p' )"
      wl-copy --primary    <<< "$ACTUAL_URL"
      wl-copy              <<< "$ACTUAL_URL"
      notify-send "Actual url" "$ACTUAL_URL"
    '';
  };

  desktopItem   = pkgs.makeDesktopItem {
    desktopName = "unshorten url expand";
    exec        = "url-unshorten";
    name        = "url-unshorten";
    type        = "Application"  ;
    icon        = "gtk-cut"      ;
    categories  = [ "Network"   ];
    };

  in pkgs.buildEnv {
    name  = "url-unshorten-wrapper";
    paths = [ script desktopItem ];
    meta.mainProgram = "url-unshorten";
  };
};}
