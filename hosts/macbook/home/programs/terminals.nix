{ pkgs, ... }:

{
  programs.ghostty = {
    enable = true;
    # Ghostty.app is installed natively in /Applications/Ghostty.app on macOS;
    # nixpkgs' ghostty derivation targets GTK4 on Linux.
    package = null;
    enableFishIntegration = true;
    settings = {
      command = "${pkgs.fish}/bin/fish --login --interactive";
    };
  };
}
