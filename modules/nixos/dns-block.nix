{ lib, ... }:

# Domains this machine must not resolve, each with every subdomain.
#
# systemd-resolved (v258+) can delegate a domain to its own DNS server through
# /etc/systemd/dns-delegate.d. Here each blocked domain is delegated to
# 127.0.0.2, where nothing listens, so the lookup fails at once instead of
# reaching a real resolver. A delegate is never used as a default route, and
# the longest matching domain wins, so it also beats the VPN's catch-all route
# (Mullvad's `~.`) and only these domains are affected.
#
# The `~` makes it a routing-only domain. Without it systemd-resolved would
# also treat the domain as a search suffix and send single-label lookups
# (`nas`, `router`) to the dead server.
#
# Applications that do their own DNS-over-HTTPS (Firefox/Zen, Chromium-based
# browsers with "secure DNS") skip the system resolver and are not covered.
let
  blockedDomains = [
    "xferrecords.com"
  ];
in
{
  services.resolved.enable = true;

  environment.etc."systemd/dns-delegate.d/blocked-domains.dns-delegate".text = ''
    [Delegate]
    DNS=127.0.0.2
    Domains=${lib.concatMapStringsSep " " (domain: "~${domain}") blockedDomains}
  '';
}
