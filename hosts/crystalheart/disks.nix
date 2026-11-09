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
  # NixOS lives in its own top-level subvolumes next to Arch's @, @home, and
  # @var.
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

  # ZRAM is configured in modules/nixos/boot.nix. No disk swap.
  swapDevices = [ ];
}
