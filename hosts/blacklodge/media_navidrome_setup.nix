{ flake.nixosModules.media_navidrome_setup = { pkgs, lib, config, ... }: let
    navidromeUid = config.users.users.navidrome.uid;
    navidromeGid = config.users.groups.navidrome.gid;
    music_position = "/srv/outside_storage_01";
  in {

    fileSystems."${music_position}" = {
      device = "/dev/disk/by-path/pci-0000:00:14.0-usbv3-0:2:1.0-scsi-0:0:0:0-part1";
      fsType = "ntfs3"; # ntfs3 is the modern kernel driver
      options = [
        "rw"
        "uid=${toString navidromeUid}"
        "gid=${toString navidromeGid}"
        
        "fmask=0133"  # files: strips x for everyone -> 644 (rw-r--r--)
        "dmask=0022"  # dirs:  -> 755 (rwxr-xr-x, traversable)
  
        "nofail"
        "relatime"
      ];
    };
    services.navidrome.settings.MusicFolder = "${music_position}/music";

  };
}
