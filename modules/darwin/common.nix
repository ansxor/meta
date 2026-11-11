{ pkgs, ... }:

{
  system.primaryUser = "darien";

  users.users.darien = {
    name = "darien";
    home = "/Users/darien";
    shell = pkgs.fish;
  };

  environment.shells = [
    pkgs.fish
    pkgs.nushell
  ];

  programs.fish.enable = true;

  time.timeZone = "America/Toronto";

  # Touch ID for sudo, including inside tmux/screen sessions via pam_reattach.
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "darien"
      "@admin"
    ];
  };

  nix.gc = {
    automatic = true;
    options = "--delete-older-than 14d";
  };
  nix.optimise.automatic = true;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.input-fonts.acceptLicense = true;

  environment.variables = {
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
    nmap
  ];
}
