{ inputs, pkgs, ... }:

{
  home.packages = with pkgs; [
    # Browsers
    firefox
    firefox-devedition
    chromium
    google-chrome
    floorp-bin
    firefoxpwa
    (callPackage ../../../pkgs/helium/package.nix { })
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default

    # Study timer
    inputs.time-timer.packages.${pkgs.stdenv.hostPlatform.system}.default

    # Claude Desktop (official Linux .deb, see pkgs/claude-desktop)
    (callPackage ../../../pkgs/claude-desktop/package.nix { })

    # Password / notes / communication
    discord
    discordchatexporter-desktop
    beeper
    notion-electron
    obsidian

    # Documents and media readers
    calibre
    wordgrinder
    evince
    loupe
    showtime
    decibels
    simple-scan
    seahorse
    yelp

    # GNOME applications
    gnome-calculator
    gnome-calendar
    gnome-characters
    gnome-clocks
    gnome-connections
    gnome-contacts
    gnome-disk-utility
    gnome-font-viewer
    gnome-logs
    gnome-maps
    gnome-music
    gnome-remote-desktop
    gnome-software
    gnome-system-monitor
    gnome-text-editor
    gnome-tweaks
    # Zenity confirmation and sudo password dialogs for the Pi config harness
    # (.pi/extensions/config-harness); without it, activation is denied.
    zenity
    gnome-weather
    nautilus
    sushi
    totem
    baobab
    gnome-backgrounds
    gnome-color-manager
    gnome-console
    gnome-control-center
    gnome-menus
    gnome-session
    gnome-settings-daemon
    gnome-shell
    gnome-shell-extensions
    gnome-tour
    gnome-user-docs
    gnome-user-share
    grilo-plugins
    malcontent
    rygel
    snapshot
    xdg-user-dirs-gtk

    # Standalone KDE applications (no Plasma session)
    kdePackages.kate
    kdePackages.okular
    kdePackages.filelight
    kdePackages.kdenlive

    # secret-tool: Tern keeps its Stencil sign-in in the Secret Service
    # through it, and falls back to files when it is missing.
    libsecret
  ];
}
