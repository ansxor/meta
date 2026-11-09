{ pkgs, ... }:

let
  # ESP shared by Arch's GRUB, Windows, and NixOS (mounted at /efi).
  efiUuid = "D19D-D2C2";

  chainload = name: class: loader: ''
    menuentry "${name}" --class ${class} {
      insmod part_gpt
      insmod fat
      insmod chain
      search --no-floppy --fs-uuid --set=root ${efiUuid}
      chainloader ${loader}
    }
  '';
in
{
  boot.loader = {
    efi.canTouchEfiVariables = true;
    efi.efiSysMountPoint = "/efi";
    timeout = 3;

    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      # os-prober cannot see Arch: it has no btrfs-subvolume support, and Arch
      # keeps its kernels in /boot inside the @ subvolume. Chainload the
      # bootloaders on the ESP instead.
      useOSProber = false;
      extraEntries =
        chainload "Arch Linux" "arch" "/EFI/GRUB/grubx64.efi"
        + chainload "Windows Boot Manager" "windows" "/EFI/Microsoft/Boot/bootmgfw.efi";
      configurationLimit = 10;
      gfxmodeEfi = "1920x1080";
    };
  };

  # The Arch install used linux-cachyos-bore-lto. nix-cachyos-kernel packages
  # it, but its binary cache is offline after a server compromise
  # (xddxdd/nix-cachyos-kernel#110), making every kernel update a local
  # Clang LTO build. Use Zen instead: full preemption, 1000 Hz, BBRv3, BFQ,
  # and sched_ext. The sched_ext scheduler in gaming.nix supplies the
  # low-latency behavior BORE provided.
  boot.kernelPackages = pkgs.linuxPackages_zen;

  boot.kernelParams = [
    "loglevel=3"
    # AMD P-State EPP autonomous mode; the 5700X3D reports active mode.
    "amd_pstate=active"
    # Carried over from /proc/cmdline; remove if PCIe ASPM behaves.
    "pcie_aspm=off"
    # The Arch install disabled zswap because zram is used instead.
    "zswap.enabled=0"
  ];

  boot.consoleLogLevel = 3;
  boot.tmp.cleanOnBoot = true;
  boot.supportedFilesystems = [
    "btrfs"
    "vfat"
    "ntfs"
    "exfat"
  ];

  # 32 GB RAM: half-size zram with zstd, same as zram-generator on Arch.
  zramSwap = {
    enable = true;
    memoryPercent = 50;
    algorithm = "zstd";
    priority = 100;
  };

  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    fileSystems = [ "/" ];
  };

  # Arch used snapper + snapper timers. NixOS generations cover system
  # rollback; snapper is kept for / and user-visible snapshots.
  services.snapper = {
    snapshotRootOnBoot = false;
    configs.root = {
      SUBVOLUME = "/";
      ALLOW_USERS = [ "answer" ];
      TIMELINE_CREATE = true;
      TIMELINE_CLEANUP = true;
    };
  };
}
