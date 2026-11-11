{ pkgs, ... }:

{
  programs.bat.enable = true;
  programs.eza.enable = true;
  programs.btop.enable = true;

  programs.tmux = {
    enable = true;
    extraConfig = ''
      set -g mouse on
    '';
    plugins = [ pkgs.tmuxPlugins.sensible ];
  };

  programs.zellij.enable = true;
  programs.helix.enable = true;
  programs.nushell = {
    enable = true;
    loadSessionVariables = true;
  };
}
