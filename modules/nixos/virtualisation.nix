{
  config,
  lib,
  pkgs,
  ...
}:

{
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      swtpm.enable = true;
    };
  };

  virtualisation.spiceUSBRedirection.enable = true;

  programs.virt-manager.enable = true;

  environment.systemPackages = with pkgs; [
    distrobox
    looking-glass-client
    OVMF
    qemu_kvm
    swtpm
    virtiofsd
    virt-manager
    winboat
  ];
}
