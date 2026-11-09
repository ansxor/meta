{ inputs, ... }:

# Hex: local voice dictation. Installs `hex`, its desktop launcher and the
# hex.service user unit. Not started at login (autostart = false), so
# `hex` or the launcher starts it; Nix owns updates, not the in-app updater.
# After the first switch, download a speech model once: `hex model install`.
# On GNOME, global shortcuts come from the GlobalShortcuts portal when it has
# one; otherwise bind `hex dictation start` / `stop` in GNOME keyboard
# shortcuts. Paste goes through the RemoteDesktop portal there.
{
  imports = [ inputs.hex.homeManagerModules.hex ];

  programs.hex.enable = true;
}
