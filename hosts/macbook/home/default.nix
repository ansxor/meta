{
  config,
  ...
}:

{
  imports = [
    ./packages/cli.nix
    ./packages/development.nix
    ./packages/media.nix
    ./programs/fish.nix
    ./programs/git.nix
    ./programs/omp.nix
    ./programs/shell-tools.nix
    ./programs/terminals.nix
    ./programs/user-services.nix
    ./dotfiles.nix
  ];

  home = {
    username = "darien";
    homeDirectory = "/Users/darien";
    stateVersion = "26.05";
    sessionPath = [
      "${config.home.homeDirectory}/.local/bin"
      # `bun add -g` globals. bun itself comes from nixpkgs; this dir is
      # prepended, so it must not contain a bun binary.
      "${config.home.homeDirectory}/.bun/bin"
      "${config.home.homeDirectory}/.cargo/bin"
      "/opt/homebrew/bin"
      "/opt/homebrew/sbin"
      "${config.home.homeDirectory}/.lmstudio/bin"
      "${config.home.homeDirectory}/.hermes/node/bin"
      "${config.home.homeDirectory}/.orbstack/bin"
    ];
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };

  xdg.enable = true;

  programs.home-manager.enable = true;
}
