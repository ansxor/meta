let
  rootUuid = "9657f7fc-b2a9-4d27-8e13-905cc7238ba5";
  efiUuid = "D19D-D2C2";

  # The home subvolume carried over from the Arch install.
  homeSubvolume = "@home";

  btrfs = subvolume: extraOptions: {
    device = "/dev/disk/by-uuid/${rootUuid}";
    fsType = "btrfs";
    options = [
      "subvol=${subvolume}"
      "compress=zstd:3"
      "ssd"
      "discard=async"
      "space_cache=v2"
    ]
    ++ extraOptions;
  };
in
{
  # NixOS lives in its own top-level subvolumes next to @home.
  fileSystems."/" = btrfs "@nixos" [ ];

  # Separate from / so snapper snapshots of / exclude the store.
  fileSystems."/nix" = btrfs "@nix" [ "noatime" ];

  # snapper's root config needs /.snapshots to be a subvolume.
  fileSystems."/.snapshots" = btrfs "@nixos-snapshots" [ ];

  fileSystems."/home" = btrfs homeSubvolume [ ];

  fileSystems."/efi" = {
    device = "/dev/disk/by-uuid/${efiUuid}";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
      "codepage=437"
      "iocharset=ascii"
      "shortname=mixed"
      "utf8"
      "errors=remount-ro"
    ];
  };

  # Samsung 990 PRO: Steam library and other data that can be downloaded
  # again. Nothing needed to boot lives here, so a missing drive only skips
  # the mount.
  fileSystems."/mnt/games" = {
    device = "/dev/disk/by-label/games";
    fsType = "ext4";
    options = [
      "noatime"
      "nofail"
      "x-systemd.device-timeout=10s"
    ];
  };

  # Seagate SATA SSD: restic repository for /home, see backup.nix.
  fileSystems."/mnt/backup" = {
    device = "/dev/disk/by-label/backup";
    fsType = "ext4";
    options = [
      "noatime"
      "nofail"
      "x-systemd.device-timeout=10s"
    ];
  };

  # The directory on the freshly made filesystem is owned by root.
  systemd.tmpfiles.rules = [
    "d /mnt/games 0755 answer answer -"
    "d /mnt/backup 0700 root root -"
  ];

  # ZRAM is configured in modules/nixos/boot.nix. No disk swap.
  swapDevices = [ ];
}
