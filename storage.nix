{ config, pkgs, vars, ... }:
let
  disk = {
    d1 = "/dev/disk/by-id/ata-disk1";
    d2 = "/dev/disk/by-id/ata-disk2";
  };
  mountDir = "/mnt/raid";
in
{
  boot.swraid = {
    enable = true;
    mdadmConf = ''
      DEVICE ${disk.d1}
      DEVICE ${disk.d2}
      ARRAY /dev/md0 level=raid1 num-devices=2 metadata=1.2 name=cloud-replacement:0 devices=${disk.d1},${disk.d2}
    '';
  };

  fileSystems."${mountDir}" = {
    options = [ "compress=zstd:3" "space_cache=v2" "noatime" "discard=async" "autodefrag" ];
    device = "/dev/md0";
    fsType = "btrfs";
  };
}
