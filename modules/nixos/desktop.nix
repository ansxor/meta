{
  lib,
  pkgs,
  ...
}:

let
  ccacheDir = "/var/cache/ccache";

  kdeCcacheStdenv = pkgs.ccacheStdenv.override {
    extraConfig = ''
      export CCACHE_COMPRESS=1
      export CCACHE_SLOPPINESS=random_seed,include_file_mtime,include_file_ctime
      export CCACHE_NOHASHDIR=1
      export CCACHE_DIR="${ccacheDir}"
      export CCACHE_UMASK=007
      if [ ! -d "$CCACHE_DIR" ] || [ ! -w "$CCACHE_DIR" ]; then
        export CCACHE_DISABLE=1
      fi
    '';
  };

  ccacheMkKdeDerivation = pkgs.kdePackages.mkKdeDerivation.override {
    stdenv = kdeCcacheStdenv;
  };

  replaceKde = pkg: patches: {
    oldDependency = pkg;
    newDependency = (pkg.override { mkKdeDerivation = ccacheMkKdeDerivation; }).overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ patches;
    });
  };
in
{
  services.xserver.enable = true;
  services.xserver.xkb.layout = "us,ca";
  services.libinput.enable = true;

  services.displayManager.gdm.enable = true;
  services.displayManager.defaultSession = "plasma";
  services.desktopManager.gnome.enable = true;
  services.desktopManager.plasma6.enable = true;
  programs.kde-pim.enable = false;
  programs.ssh.askPassword = lib.getExe pkgs.kdePackages.ksshaskpass;

  # Compiler cache for fast iterative rebuilds of our locally patched KDE packages.
  # Managed directly via tmpfiles (instead of programs.ccache.enable) because nixpkgs'
  # programs.ccache creates a Perl security wrapper that fails ensure-wrapper-integrity.
  # The trailing "?" on extra-sandbox-paths and the CCACHE_DISABLE fallback keep the
  # first switch (before tmpfiles creates /var/cache/ccache) completely self-bootstrapping.
  systemd.tmpfiles.rules = [ "d ${ccacheDir} 0770 root nixbld -" ];
  nix.settings.extra-sandbox-paths = [ "${ccacheDir}?" ];

  # Custom Plasma 6 patches developed in ~/Workspace/kde to reduce start menu
  # open/close and KRunner search latency (using GNOME BoxPointer/search as reference).
  # All patches are implementation/QML-only (zero public header/ABI changes), so we
  # graft them via system.replaceDependencies to avoid recompiling ~30 downstream
  # KDE packages (powerdevil, plasma-pa, xdg-desktop-portal-kde, etc.) on every tweak.
  system.replaceDependencies.replacements = [
    (replaceKde pkgs.kdePackages.krunner [
      ../../patches/kde/krunner/fast-runner-nonblocking-matches.patch
    ])
    (replaceKde pkgs.kdePackages.kwin [
      ../../patches/kde/kwin/slidingpopups-gnome-timing-and-easing.patch
      ../../patches/kde/kwin/fadingpopups-fast-close.patch
      ../../patches/kde/kwin/launcher-keystroke-buffer.patch
    ])
    (replaceKde pkgs.kdePackages.libplasma [
      ../../patches/kde/libplasma/appletpopup-no-sync-on-hide.patch
      ../../patches/kde/libplasma/popupplasmawindow-queue-early-keys.patch
    ])
    (replaceKde pkgs.kdePackages.plasma-desktop [
      ../../patches/kde/plasma-desktop/kickoff-and-popup-latency.patch
    ])
    (replaceKde pkgs.kdePackages.plasma-workspace [
      ../../patches/kde/plasma-workspace/runnermodel-prewarm-and-zero-debounce.patch
      ../../patches/kde/plasma-workspace/shellcorona-skip-dbus-single-launcher.patch
    ])
  ];

  # KDE Connect protocol through the GSConnect GNOME Shell extension.
  programs.kdeconnect = {
    enable = true;
    package = lib.mkForce pkgs.gnomeExtensions.gsconnect;
  };

  # KDE Partition Manager with its kpmcore root helper.
  programs.partition-manager.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  services.pulseaudio.enable = false;

  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };

  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.devmon.enable = true;
  services.upower.enable = true;

  environment.systemPackages = with pkgs.gnomeExtensions; [
    appindicator
    forge
    pomodoro-timer
    just-perfection
  ];

  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      cascadia-code
      monaspace
      input-fonts
      nerd-fonts.symbols-only
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
    ];
    fontDir.enable = true;
  };
}
