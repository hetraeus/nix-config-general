{ perSystem = { pkgs, lib, ... }: {
  packages.panicstopprinter = let
    script = pkgs.writeShellApplication {
      name          = "panicstopprinter";
      runtimeInputs = [ pkgs.cups ];
      text = ''
        cancel -ax && printf '\e]777;notify;Printers;Jobs cancelled!\a'
      '';
    };
  in pkgs.makeDesktopItem {
    name        = "PANIC-STOP-PRINTER-JOBS";
    exec        = "${lib.getExe script}";
    terminal    = false;
    categories  = [ "Graphics" ];
    genericName = "cups emergency stop printing job";
    desktopName = "cups emergency stop printing job";
    icon        = "dialog-warning";
  };
};}
