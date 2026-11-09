{ pkgs, ... }:

{
  programs.ghostty = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      font-family = "Monaspace Neon";
      font-size = 10;
      command = "${pkgs.nushell}/bin/nu --login --interactive";
      keybind = [ "shift+enter=text:\\n" ];
      theme = "dark:Hurtado,light:Hurtado";
      quit-after-last-window-closed = true;
      quit-after-last-window-closed-delay = "5m";
    };
  };
}
