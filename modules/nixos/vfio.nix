{
  config,
  lib,
  ...
}:

{
  options.my.vfio.enable = lib.mkEnableOption ''
    VFIO PCI passthrough for the NVIDIA GPU previously passed through on Arch.
    The device is not present in the current lspci output, so this is off by
    default. Enable only after verifying the IOMMU groups.
  '';

  config = lib.mkIf config.my.vfio.enable {
    boot.kernelModules = [
      "vfio"
      "vfio_iommu_type1"
      "vfio_pci"
    ];

    boot.initrd.kernelModules = [
      "vfio"
      "vfio_iommu_type1"
      "vfio_pci"
    ];

    boot.kernelParams = [
      "vfio-pci.ids=10de:2184,10de:1aeb"
      "pcie_acs_override=downstream,multifunction"
    ];

    boot.extraModprobeConfig = ''
      options vfio-pci ids=10de:2184,10de:1aeb
      softdep drm pre: vfio-pci
    '';
  };
}
