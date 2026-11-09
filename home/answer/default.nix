{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./packages/cli.nix
    ./packages/desktop.nix
    ./packages/development.nix
    ./packages/flatpaks.nix
    ./packages/gaming.nix
    ./packages/media.nix
    ./programs/desktop-config.nix
    ./programs/easyeffects.nix
    ./programs/fish.nix
    ./programs/game-handoff.nix
    ./programs/git.nix
    ./programs/hex.nix
    ./programs/omp.nix
    ./programs/openclaw.nix
    ./programs/shell-tools.nix
    ./programs/terminals.nix
    ./programs/services.nix
    ./programs/user-services.nix
    ./dotfiles.nix
  ];

  home = {
    username = "answer";
    homeDirectory = "/home/answer";
    stateVersion = "26.05";
    sessionPath = [
      "${config.home.homeDirectory}/.local/bin"
      # `bun add -g` globals. bun itself comes from nixpkgs; this dir is
      # prepended, so it must not contain a bun binary.
      "${config.home.homeDirectory}/.bun/bin"
    ];
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      NIXOS_OZONE_WL = "1";
    };
  };

  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "${config.home.homeDirectory}/Desktop";
      documents = "${config.home.homeDirectory}/Documents";
      download = "${config.home.homeDirectory}/Downloads";
      music = "${config.home.homeDirectory}/Music";
      pictures = "${config.home.homeDirectory}/Pictures";
      projects = "${config.home.homeDirectory}/Projects";
      publicShare = "${config.home.homeDirectory}/Public";
      templates = "${config.home.homeDirectory}/Templates";
      videos = "${config.home.homeDirectory}/Videos";
    };
  };

  programs.home-manager.enable = true;
}
