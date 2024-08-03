{ lib, ... }: {
  services.dbus.implementation   = "broker";

  # POSIX shebang /bin/sh compatibility
  services.envfs.enable          = true;

  programs.nix-ld.enable         = true;

  # Copy the NixOS configuration file and link it from the resulting system
  # /run/current-system/configuration.nix
  # Useful in case of accidental deletion configuration.nix
  system.copySystemConfiguration = lib.mkForce false; # NOT SUPPORTED FOR FLAKES
}
