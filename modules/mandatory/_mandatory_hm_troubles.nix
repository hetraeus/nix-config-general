{ lib, ... }: {
  # Don't trust this clock! It gets stuck!
  programs.ncmpcpp.settings.clock_display_seconds = lib.mkForce "no";
 
}
