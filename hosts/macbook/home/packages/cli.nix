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
    coreutils
    wget

    # Multiplexers
    tmux
    zellij

    # Files, sync, backup
    aria2
    rclone
    restic

    # Captured Homebrew CLI tools with nixpkgs equivalents
    bitwarden-cli
    chezmoi
    gogcli
    himalaya
    httpie
    lazydocker
    lrzip
    nano
    qrencode
    riffdiff
    tokei
    trufflehog
    unrar
    watchexec
    watchman
    zip
  ];
}
