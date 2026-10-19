{ lib, ... }: { disko.devices.disk.main = {
# WARN: DO NOT USE disko-install ! IT GOT STUCK!
#       SET THE PASSWORD FILE BEFORE HAND!
#       BE AWARE OF PROGRAMS EATING RAM SUCH AS FIREFOX!
#
# INFO Partitioning
#
# DISKO_FILE="hosts/blacklodge/_disko.nix"
# run0 nix --extra-experimental-features 'nix-command pipe-operators flakes' run github:nix-community/disko -- --mode destroy "$DISKO_FILE"
# run0 nix --extra-experimental-features 'nix-command pipe-operators flakes' run github:nix-community/disko -- --mode format  "$DISKO_FILE"
# run0 nix --extra-experimental-features 'nix-command pipe-operators flakes' run github:nix-community/disko -- --mode mount   "$DISKO_FILE"
#
# NOTE override the device value with this:
# --disk <disk name as declared here, i.e. main> /dev/by-...
#
# INFO Installation
# Add the swap right away, so the build doesn't fail
# run0 swapon /dev/disk/by-id/<swap>
# run0 env NIX_CONFIG='experimental-features = flakes pipe-operators nix-command' nixos-install --root /mnt --flake './<flake>#<attribute>'

# WIP lanzaboote integration

type    = "disk";
device  = "/dev/disk/by-id/ata-SanDisk_SD9SB8W512G1101_1903B0800501";
content.type = "gpt";
content.partitions = {

  ESP.size = "2G";
  ESP.type = "EF00";
  ESP.content = {
    type         = "filesystem";
    format       = "vfat";
    mountpoint   = "/boot";
    mountOptions = [ "umask=0077" ];
    };

  luks.end = "-8G";
  luks.content = {
    type  = "luks";
    name  = "crypted";
    # settings.keyFile   = "/tmp/secret.key"; # Procedural
    # additionalKeyFiles = [ "/tmp/additionalSecret.key" ];
    passwordFile = "/tmp/secret.key";
    settings.allowDiscards = true;
    };

  luks.content.content = {
      type         = "btrfs";
      extraArgs    = [ "-f" ];
      subvolumes   = {
        # discard/trim enabled by default since linux 6.2
        # list the subvolumes with
        # run0 btrfs subvolume list / | column -t | fzf --ansi --height=60% --reverse --prompt='subvol> ' --accept-nth=2
        "/my_root" = { mountpoint = "/";     mountOptions = [ "compress=zstd" "lazytime" ]; };
        "/my_home" = { mountpoint = "/home"; mountOptions = [ "compress=zstd" "lazytime" ]; };
        "/my_nix"  = { mountpoint = "/nix";  mountOptions = [ "compress=zstd" "lazytime" ]; };
        "/subv"    = { mountpoint = "/subv"; mountOptions = [ "compress=zstd" "lazytime" ]; };

    };};

  plainSwap.size     = "100%";
  plainSwap.content  = {
    type             = "swap";
    discardPolicy    = "both";
    resumeDevice     = true; # resume from hiberation from this device
  # WARN: Don’t hibernate when you have at least one swap partition with randomEncryption enabled! NO encryptedSwap !
  # We have no way to set the partition into which hibernation image is saved,
  # so if your image ends up on an encrypted one you would lose it!
  # Don't use /dev/disk/by-{uuid,label}/... as your swap device when using randomEncryption as the UUIDs and
  # labels will get erased on every boot when the partition is encrypted. Best to use /dev/disk/by-partuuid/
    randomEncryption = lib.mkForce false;
    };
};};
}
