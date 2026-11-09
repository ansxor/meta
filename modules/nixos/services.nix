{
  config,
  lib,
  pkgs,
  ...
}:

{
  networking.networkmanager = {
    enable = true;
    # Arch: /etc/NetworkManager/conf.d/wifi-powersave.conf, wifi.powersave = 2.
    wifi.powersave = false;

    # Ethernet only links to the VR headset; internet traffic must stay on
    # Wi-Fi (metric 600) even when a wired connection also has a gateway.
    # NetworkManager's default is 100 for ethernet, which would win.
    settings."connection-ethernet-low-priority" = {
      "match-device" = "type:ethernet";
      "ipv4.route-metric" = 700;
      "ipv6.route-metric" = 700;
    };
  };

  # Arch ran without a host firewall (no ufw/firewalld; nftables and
  # iptables units disabled). Mullvad manages its own nftables rules.
  networking.firewall.enable = false;

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };

  services.mullvad-vpn = {
    enable = true;
    enableEarlyBootBlocking = true;
    gui.enable = true;
  };

  services.blueman.enable = true;

  services.earlyoom.enable = true;

  # Flatpak runtime and portals. The apps themselves are declared per user
  # with nix-flatpak in home/answer/packages/flatpaks.nix.
  services.flatpak.enable = true;

  # OpenSSH was installed on Arch but sshd was not enabled. Keep it off.
  services.openssh.enable = false;
}
