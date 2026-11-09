{ inputs, ... }:

# Save sync, game locks and handoffs. The host firewall is disabled
# (services.nix), so the server is reachable on LAN and Tailscale; the bearer
# token gates it.
{
  imports = [
    inputs.game-handoff.nixosModules.server
    inputs.game-handoff.nixosModules.sleep-hold
  ];

  services.game-handoff.server = {
    enable = true;
    tokenFile = "/etc/game-handoff/token";
  };

  services.game-handoff.sleepHold.enable = true;
}
