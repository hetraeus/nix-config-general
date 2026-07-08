{ perSystem = { pkgs, lib, ... }: {
  packages.printers_utils = let
    script_panic = pkgs.writeShellApplication {
      name          = "panicstopprinter";
      runtimeInputs = [ pkgs.cups ];
      text = ''
        cancel -ax && printf '\e]777;notify;Printers;Jobs cancelled!\a'
      '';
    };

    webui_script = pkgs.writeShellApplication {
      name          = "cups-webui";
      runtimeInputs = [ pkgs.gawk pkgs.cups ];
      text = ''
        awk '/^(Port|Listen)/ && !/\.sock/ {
            if ($1 == "Port") {
                port = $2
            } else {
                port = $2
                gsub(/^.*:/, "", port)
                if (port == $2 && $2 !~ /^[0-9]+$/) port = 631
            }
            print "http://localhost:" port "/printers/"
            exit
        }' /etc/cups/cupsd.conf 2>/dev/null || printf "http://localhost:631/printers/"
      '';
    };
  cups_webui = pkgs.makeDesktopItem {
    name        = "cups-webui";
    desktopName = "cups web-ui";
    genericName = "cups printers webui web-ui 631";
    icon        = "printer";
    terminal    = false;
    categories  = [ "Utility" ];
    exec        = "${lib.getExe webui_script}";
  };

  cups_panic = pkgs.makeDesktopItem {
    name        = "PANIC-STOP-PRINTER-JOBS";
    exec        = "${lib.getExe script_panic}";
    terminal    = false;
    categories  = [ "Graphics" ];
    genericName = "cups emergency stop printing job";
    desktopName = "cups emergency stop printing job";
    icon        = "dialog-warning";
  };
  in pkgs.symlinkJoin {
    name = "fmenu-emoticon";
    paths = [ cups_webui cups_panic ];
  };

  
};}
