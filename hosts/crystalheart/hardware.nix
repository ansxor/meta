{
  config,
  lib,
  pkgs,
  ...
}:

let
  # CoreCtrl's _global_ profile in LACT 0.10 (config version 7) form. LACT
  # writes the curve to the GPU's 5-point PMFW fan curve, whose temperatures
  # are junction (hotspot) readings; with a custom curve it applies only the
  # zero-RPM PMFW options.
  lactConfig = pkgs.writeText "lact-config.yaml" ''
    version: 7
    daemon:
      log_level: info
      admin_group: wheel
      disable_clocks_cleanup: false
    apply_settings_timer: 5
    gpus:
      1002:747E-1DA2:475D-0000:2d:00.0:
        fan_control_enabled: true
        fan_control_settings:
          mode: curve
          static_speed: 0.5
          temperature_key: junction
          interval_ms: 500
          curve:
            35: 0.2
            52: 0.22
            67: 0.3
            78: 0.5
            85: 0.82
        pmfw_options:
          zero_rpm: true
          zero_rpm_threshold: 55
        power_cap: 280.0
        performance_level: manual
        max_core_clock: 2635
        max_memory_clock: 1219
        voltage_offset: 0
        power_profile_mode_index: 5
    current_profile: null
    auto_switch_profiles: false
  '';
in
{
  # AMD Ryzen 7 5700X3D, AMD RX 7700 XT (Navi 32), MT7922 Wi-Fi, RTL8125 2.5GbE.
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
    "amdgpu"
    "mt7921e"
    "r8169"
  ];

  boot.initrd.kernelModules = [ "amdgpu" ];

  boot.kernelModules = [
    "kvm-amd"
    "nct6683"
    "jc42"
    "k10temp"
    "uhid"
  ];

  boot.extraModprobeConfig = ''
    # MT7922: keep deep power saving off; this was required on the Arch install.
    options mt7921e disable_lps_deep=1
  '';

  boot.kernel.sysctl = {
    "vm.swappiness" = 100;
    "vm.page-cluster" = 0;
    "vm.watermark_scale_factor" = 125;
    "vm.watermark_boost_factor" = 0;
  };

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.bluetooth.enable = true;
  hardware.i2c.enable = true;

  # Matches amdgpu.ppfeaturemask=0xffffffff from the Arch kernel command line.
  # The NixOS default (0xfffd7fff) is safer but omits features Arch enabled.
  hardware.amdgpu.overdrive = {
    enable = true;
    ppfeaturemask = "0xffffffff";
  };

  # Arch had rocm-opencl-runtime; expose the ROCm OpenCL ICD to the
  # graphics-driver environment used by /run/opengl-driver.
  hardware.amdgpu.opencl.enable = true;

  services.xserver.videoDrivers = [ "modesetting" ];

  # OpenTabletDriver is installed; harmless when no tablet is attached.
  hardware.opentabletdriver.enable = true;

  # Same CPU policy as Arch: performance governor (amd_pstate active mode,
  # which pins EPP to performance) and no power-profiles-daemon, which the
  # GNOME module would otherwise enable. On Arch the governor is
  # set by CoreCtrl's global profile at login; here it applies from boot.
  powerManagement.cpuFreqGovernor = "performance";
  services.power-profiles-daemon.enable = false;

  # LACT owns GPU tuning. The values are CoreCtrl's global profile, which is
  # what actually ran on Arch. The file is written by hand,
  # as services.lact would write it, because services.lact.settings renders
  # the fan curve's temperature keys as quoted strings and LACT then rejects
  # the whole config ("expected i32"). It lives in the store, so changes made
  # in the LACT GUI are not saved; edit them here.
  services.lact.enable = true;
  environment.etc."lact/config.yaml" = lib.mkIf config.services.lact.enable {
    source = lactConfig;
  };
  systemd.services.lactd = lib.mkIf config.services.lact.enable {
    restartTriggers = [ lactConfig ];
  };

  # MSI Mystic Light / motherboard RGB.
  services.hardware.openrgb.enable = true;

  # Logitech wireless devices (mouse/receiver).
  programs.solaar.enable = true;

  # Rules reproduced from the Arch install.
  services.udev.extraRules = ''
    # Sunshine: allow access to uinput/uhid and its virtual pads.
    KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", GROUP="input", MODE="0660", TAG+="uaccess"
    KERNEL=="uhid", GROUP="input", MODE="0660", TAG+="uaccess"
    SUBSYSTEMS=="input", ATTRS{name}=="Sunshine X-Box One (virtual) pad", GROUP="input", MODE="0660", TAG+="uaccess"
    SUBSYSTEMS=="input", ATTRS{name}=="Sunshine gamepad (virtual) motion sensors", GROUP="input", MODE="0660", TAG+="uaccess"
    SUBSYSTEMS=="input", ATTRS{name}=="Sunshine Nintendo (virtual) pad", GROUP="input", MODE="0660", TAG+="uaccess"

    # Keychron V1 exposes a joystick interface that confuses some games.
    KERNEL=="event*", SUBSYSTEM=="input", ENV{ID_VENDOR_ID}=="3434", ENV{ID_INPUT_JOYSTICK}=="*?", ENV{ID_INPUT_JOYSTICK}=""

    # Make Intel RAPL powercap counters readable (harmless on AMD).
    SUBSYSTEM=="powercap", KERNEL=="intel-rapl*", RUN+="${pkgs.coreutils}/bin/chmod a+r /sys/%p/energy_uj"
  '';
}
