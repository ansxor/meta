{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Shell, prompt, and CLI basics
    fish
    nushell
    starship
    zoxide
    fzf
    bat
    eza
    btop
    fastfetch
    pfetch
    htop
    ncdu
    duf
    ripgrep
    fd
    jq
    yq
    jless
    dasel
    file
    which
    tree
    wl-clipboard
    libva-utils
    vdpauinfo
    xdotool
    ptyxis
    woeusb-ng
    mcaselector

    # Terminals and multiplexers
    ghostty
    foot
    warp-terminal
    tmux
    zellij

    # Wayland desktop utilities
    wlr-randr
    kanshi
    wlsunset
    grim
    slurp
    flameshot
    satty
    swappy
    imv
    feh
    nsxiv
    libnotify
    playerctl
    pavucontrol
    helvum
    qjackctl
    pulsemeeter

    # Files, sync, backup
    file-roller
    qbittorrent
    aria2
    rclone
    restic
    restic-browser

    # Music
    mpc
    ncmpcpp
    mympd
    carla

    # Misc desktop tooling
    wakatime-cli
    tokei
    chezmoi
    tecla
    gtk4-layer-shell

    # Captured AUR/CLI tools with nixpkgs equivalents
    ark
    bind
    bruno
    btrfs-assistant
    bubblewrap # Codex sandbox (codex itself comes from mise)
    cdecrypt
    chatgpt
    codex-acp
    dnsmasq
    docker-buildx
    docker-compose
    docker-sbx
    efibootmgr
    epiphany
    espanso-wayland
    nvi
    firejail
    fx
    gogcli
    gnome-randr
    httpie
    hunspellDicts.en-us
    jack-example-tools
    ktailctl
    lazydocker
    lens
    lftp
    libvdpau-va-gl
    lrzip
    man-db
    nano
    nethogs
    networkmanagerapplet
    noisetorch
    orca
    powershell
    riffdiff
    snapshot
    speedcrunch
    unityhub
    unrar
    vicinae
    watchexec
    watchman
    wlopm
    wmctrl
    xdg-user-dirs-gtk
    xeyes
    yaak
    zap
    zip
  ];
}
