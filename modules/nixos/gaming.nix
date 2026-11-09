{
  config,
  inputs,
  pkgs,
  ...
}:

{
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

  programs.gamemode.enable = true;

  # No capSysNice: its setcap wrapper cannot hand over CAP_SYS_NICE inside
  # Steam's bubblewrap sandbox (no_new_privs), so "gamescope ... %command%"
  # launch options die with "failed to inherit capabilities". ananicy-cpp
  # below already raises gamescope's priority.
  programs.gamescope.enable = true;

  hardware.steam-hardware.enable = true;

  # Logitech wheel (G923): hid-logitech-dd kernel module, udev rules,
  # logi-wheel settings app and the Xbox-to-PC mode switch, from the
  # logitech-trueforce flake (its NixOS module is not used because its kernel
  # module build breaks the module aggregation; see pkgs/hid-logitech-dd).
  # The old G920 is served by the in-tree hid-logitech-hidpp and needs
  # nothing extra.
  boot.extraModulePackages = [
    (config.boot.kernelPackages.callPackage ../../pkgs/hid-logitech-dd/package.nix {
      src = inputs.logitech-trueforce;
      version = "0.42.6";
    })
  ];
  # uhid: the logi-ffb proxy's virtual wheel needs /dev/uhid. In the initrd
  # too, so the driver registers before the in-tree hid-logitech-hidpp can
  # claim the wheel at boot.
  boot.kernelModules = [
    "hid-logitech-dd"
    "uhid"
  ];
  boot.initrd.kernelModules = [ "hid-logitech-dd" ];
  boot.extraModprobeConfig = ''
    softdep hid-logitech-hidpp pre: hid-logitech-dd
    softdep hid-logitech pre: hid-logitech-dd
    blacklist hid-logitech-new
  '';
  services.udev.packages = [
    inputs.logitech-trueforce.packages.${pkgs.stdenv.hostPlatform.system}.udev-rules
  ];
  environment.systemPackages =
    with inputs.logitech-trueforce.packages.${pkgs.stdenv.hostPlatform.system}; [
      logi-wheel
      logi-wheel-modeswitch
    ];

  # WiVRn (OpenXR streaming to standalone headsets), built from the
  # git.shsbs.xyz fork. The module also turns on avahi user-service
  # publishing, which the server needs to advertise itself to the headset.
  services.wivrn = {
    enable = true;
    package = inputs.wivrn.packages.${pkgs.stdenv.hostPlatform.system}.default;
    openFirewall = true;
    steam.package = config.programs.steam.package;
    # Lets Steam games find WiVRn without per-game launch options.
    steam.importOXRRuntimes = true;
  };

  # CachyOS-like low-latency scheduling without a custom kernel. Zen has
  # CONFIG_SCHED_CLASS_EXT; scx_lavd is the gaming/desktop-oriented
  # sched_ext scheduler. Its default autopilot mode adapts to load.
  services.scx = {
    enable = true;
    package = pkgs.scx.rustscheds;
    scheduler = "scx_lavd";
  };

  # CachyOS' process-priority rules, applied by ananicy-cpp.
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
  };
}
