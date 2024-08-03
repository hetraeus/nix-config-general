{ lib }: { disko.devices.disk.main = {
# INFO: usage
# run0 nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount "$this_nix_file"
# TEST still WIP:

# TODO: remove relative entries in the hardware module
# lanzaboote integration

type    = "disk";
device  = "/dev/disk/by-path/pci-0000:00:17.0-ata-1.0";
content = { type = "gpt";

  partitions.ESP = { size = "2G"; type = "EF00"; };
  partitions.ESP.content = {
    type         = "filesystem";
    format       = "vfat";
    mountpoint   = "/boot";
    mountOptions = [ "umask=0077" ];
    };

  partitions.luks.size = "-8G";
  partitions.luks.content = {
    type  = "luks";
    name  = "crypted";
    # disable settings.keyFile if you want to use interactive password entry
    passwordFile = "/tmp/secret.key"; # Interactive
    #additionalKeyFiles = [ "/tmp/additionalSecret.key" ];
    # settings.keyFile = "/tmp/secret.key";
    settings.allowDiscards = true;
    content = {
      type  = "btrfs"; extraArgs  = [ "-f" ];
      subvolumes = {
        # discard/trim enabled by default since linux 6.2
        "/my_root" = { mountpoint = "/";     mountOptions = [ "compress=zstd" "lazytime" ]; };
        "/my_home" = { mountpoint = "/home"; mountOptions = [ "compress=zstd" "lazytime" ]; };
        "/my_nix"  = { mountpoint = "/nix";  mountOptions = [ "compress=zstd" "lazytime" ]; };
        "/subv"    = { mountpoint = "/subv"; mountOptions = [ "compress=zstd" "lazytime" ]; };

    };};};


 plainSwap.size     = "100%";
  plainSwap.content  = {
    type             = "swap";
    discardPolicy    = "both";
    resumeDevice     = true; # resume from hiberation from this device
  # WARN: Don’t hibernate when you have at least one swap partition with randomEncryption enabled!
  # We have no way to set the partition into which hibernation image is saved,
  # so if your image ends up on an encrypted one you would lose it!
  # Don't use /dev/disk/by-{uuid,label}/... as your swap device when using randomEncryption as the UUIDs and
  # labels will get erased on every boot when the partition is encrypted. Best to use /dev/disk/by-partuuid/
    randomEncryption = lib.mkForce false;
    };
};};
}
