{ pkgs, ... }:

{
  programs.fish = {
    enable = true;

    shellAliases = {
      ls = "eza --icons";
      ll = "eza -la --icons";
      la = "eza -la --icons";
      cat = "bat";
      pbcopy = "wl-copy";
      pbpaste = "wl-paste";
    };

    interactiveShellInit = ''
      set -gx OLLAMA_FLASH_ATTENTION 1
      set -gx fish_greeting ""
    '';

    plugins = [
      {
        name = "autopair";
        src = pkgs.fishPlugins.autopair.src;
      }
    ];
  };

  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableFishIntegration = true;
  };

  programs.mise = {
    enable = true;
    enableFishIntegration = true;
  };
}
