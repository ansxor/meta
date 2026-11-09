{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Keep the same UID/GID as Arch so /home ownership is preserved.
  users.groups.answer.gid = 1000;

  users.users.answer = {
    isNormalUser = true;
    uid = 1000;
    group = "answer";
    description = "answer";
    shell = pkgs.fish;
    # Arch's home is drwx--x--- with an ACL granting libvirt-qemu search (x)
    # access. The NixOS default (700) would be applied on every activation
    # and recompute the ACL mask to ---, breaking that access.
    homeMode = "710";
    # Start the user manager at boot, as Arch did, so Home Manager user
    # services (see home/answer/programs/user-services.nix) run without a login.
    linger = true;
    extraGroups = [
      "wheel"
      "docker"
      "input"
      "kvm"
      "libvirtd"
      "networkmanager"
      "video"
      "render"
      "audio"
    ];
  };

  # Keep accounts mutable so `passwd` works on the installed system.
  # For a fully declarative password, replace this with hashedPasswordFile.
  users.mutableUsers = true;

  security.sudo.wheelNeedsPassword = true;
  security.polkit.enable = true;
  security.rtkit.enable = true;

  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };
  console.keyMap = "us";

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
    trusted-users = [
      "root"
      "@wheel"
    ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.optimise.automatic = true;

  # Unfree packages explicitly present on the Arch system: 1Password,
  # Google Chrome, Steam, Discord, Spotify, VS Code, VirtualBox extension pack.
  nixpkgs.config.allowUnfree = true;

  # nixpkgs' mozc 2.30.5544.102 fails to build with the Qt uic shipped in this
  # revision: the .ui file uses a leading "::" in a custom class name, which
  # uic rejects. Drop the leading "::" so ibus-mozc can build.
  nixpkgs.overlays = [
    (final: prev: {
      # Calibre's Piper TTS dependency runs an upstream test that expects an
      # older NumPy error string; skip tests for this pure-Python package.
      python3Packages = prev.python3Packages.overrideScope (
        pyFinal: pyPrev: {
          pyopenjtalk-plus = pyPrev.pyopenjtalk-plus.overridePythonAttrs (_: {
            doCheck = false;
          });
        }
      );

      # Calibre's build-time test suite expects speech-dispatcher Python
      # bindings that are not in its build closure. Runtime TTS still uses
      # speech-dispatcher from the system.
      calibre = prev.calibre.overrideAttrs (_: {
        doCheck = false;
        doInstallCheck = false;
      });

      mozc = prev.mozc.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace src/gui/dictionary_tool/dictionary_tool.ui \
            --replace-fail '::mozc::gui::DictionaryContentTableWidget' \
            'mozc::gui::DictionaryContentTableWidget'
        '';
      });
    })
  ];

  nixpkgs.config.input-fonts.acceptLicense = true;
  nixpkgs.config.permittedInsecurePackages = [
    # SideQuest still ships Electron 29. Kept for parity with Arch; remove when
    # an updated package lands or use the Flatpak.
    "sidequest-0.10.42"
    # Ventoy is flagged for bundled binary blobs; kept for parity.
    "ventoy-1.1.18"
  ];

  # Helps run unpatched binaries (npm/npx, AppImages, vendor tools) during the
  # transition. Prefer real nixpkgs packages where possible.
  programs.nix-ld = {
    enable = true;
    # Merged with the module's default set. hidapi: SteamControllerGyroDSU
    # (home/answer/programs/user-services.nix). The rest are dlopened by
    # Tern's GUI (~/Downloads/Tern-*/tern/tern).
    libraries = with pkgs; [
      hidapi
      libGL
      vulkan-loader
      wayland
      libxcb
      libxkbcommon
      libpulseaudio
      pam
      webkitgtk_4_1
    ];
  };
  programs.appimage = {
    enable = true;
    binfmt = true;
  };
  programs.dconf.enable = true;
  programs.fuse.enable = true;

  services.gnome.gnome-keyring.enable = true;

  programs.fish.enable = true;

  # The NixOS modules (not plain packages) provide the setgid wrappers the
  # desktop app requires for browser integration (1Password-BrowserSupport)
  # and CLI integration (op), plus the polkit policy for system unlock.
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "answer" ];
  };
  # 1Password only answers browser extensions from browsers on its built-in
  # list; Zen is not on it. The wrapped binary shows up under both names.
  environment.etc."1password/custom_allowed_browsers" = {
    text = ''
      .zen-wrapped
      zen
    '';
    mode = "0755";
  };

  i18n.inputMethod = {
    enable = true;
    type = "ibus";
    ibus.engines = [ pkgs.ibus-engines.mozc ];
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  environment.systemPackages = with pkgs; [
    git
    gnupg
    curl
    wget
    file
    which
    tree
    jq
    yq
    jless
    dasel
    lsof
    strace
    pciutils
    usbutils
    btrfs-progs
    compsize
    snapper
    nvme-cli
    smartmontools
    ntfs3g
    exfatprogs
    dosfstools
    lm_sensors
    ethtool
    nmap
    arp-scan
    net-tools
    inotify-tools
    ventoy
    usbimager
  ];
}
