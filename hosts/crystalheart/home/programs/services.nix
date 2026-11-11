{ config, ... }:

{
  services.mpd = {
    enable = true;
    musicDirectory = "${config.xdg.userDirs.music}";
    dataDir = "${config.xdg.stateHome}/mpd";
    extraConfig = ''
      audio_output {
        type "pipewire"
        name "PipeWire Sound Server"
      }
    '';
  };

  services.darkman = {
    enable = true;
    settings = {
      lat = 45.4;
      lng = -75.7;
      dbusserver = true;
    };
  };

  # Tray client at login; replaces its own ~/.config/autostart entry.
  services.nextcloud-client = {
    enable = true;
    startInBackground = true;
  };

  services.syncthing = {
    enable = true;
    tray.enable = true;
  };
}
