{ inputs, ... }:

{
  imports = [
    ./hardware.nix
    ./disks.nix

    ../../modules/nixos/common.nix
    ../../modules/nixos/backup.nix
    ../../modules/nixos/boot.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/dns-block.nix
    ../../modules/nixos/gaming.nix
    ../../modules/nixos/game-handoff.nix
    ../../modules/nixos/services.nix
    ../../modules/nixos/virtualisation.nix
    ../../modules/nixos/vfio.nix

    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  # Same as Arch (the flake attribute stays lowercase), so LAN/Tailscale
  # names, GSConnect (KDE Connect) peers, and Syncthing see the same machine.
  networking.hostName = "CrystalHeart";

  # Set once at install time. Do not bump this on upgrades.
  system.stateVersion = "26.05";
}
