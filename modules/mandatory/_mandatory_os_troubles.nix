{ lib, ... }: {
  hardware.usbStorage.manageShutdown = lib.mkForce true;
}
