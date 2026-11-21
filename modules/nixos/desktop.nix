{
  pkgs,
  ...
}:

{
  services.xserver.enable = true;
  services.xserver.xkb.layout = "us,ca";
  services.libinput.enable = true;

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  programs.kde-pim.enable = false;

  # KDE Connect protocol through the GSConnect GNOME Shell extension.
  programs.kdeconnect = {
    enable = true;
    package = pkgs.gnomeExtensions.gsconnect;
  };

  # KDE Partition Manager with its kpmcore root helper.
  programs.partition-manager.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  services.pulseaudio.enable = false;

  services.printing.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };

  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.devmon.enable = true;
  services.upower.enable = true;

  environment.systemPackages = with pkgs.gnomeExtensions; [
    appindicator
    forge
    pomodoro-timer
    just-perfection
  ];

  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      cascadia-code
      monaspace
      input-fonts
      nerd-fonts.symbols-only
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
    ];
    fontDir.enable = true;
  };
}
