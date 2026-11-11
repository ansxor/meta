{ ... }:

{
  imports = [
    ../../modules/darwin/common.nix
    ../../modules/darwin/homebrew.nix
    ../../modules/darwin/system.nix
  ];

  networking.hostName = "MacBook";
  networking.localHostName = "MacBook";
  networking.computerName = "MacBook";

  # Set once at install time. Do not bump this on upgrades.
  system.stateVersion = 6;
}
