{
  config,
  pkgs,
  lib,
  ...
}:

# Arch `systemctl --user` units that are still relevant and run code that
# lives in the home directory (not packaged by nixpkgs). Each unit mirrors the
# Arch unit it replaces; the binaries stay at their $HOME paths. Each unit
# is conditioned on its program (or config), so it is skipped rather than
# restart-looped where that is missing.
#
# Units provided by NixOS or Home Manager already (pipewire, wireplumber,
# darkman, mpd, syncthing, opentabletdriver, gnome-keyring, xdg-user-dirs,
# ghostty, systemd-tmpfiles) are intentionally absent: their Arch copies were
# removed instead of being duplicated here.

let
  home = config.home.homeDirectory;
  user = config.home.username;

  # NixOS-provided binaries first, then the per-user dirs the Arch units
  # relied on. No /usr or /usr/local: those do not exist on NixOS.
  systemPath = [
    "/run/current-system/sw/bin"
    "/etc/profiles/per-user/${user}/bin"
  ];
  homePath = [
    "${home}/.local/bin"
    "${home}/bin"
    "${home}/.nix-profile/bin"
    "${home}/.npm-global/bin"
    "${home}/.bun/bin"
    "${home}/.cargo/bin"
    "${home}/go/bin"
    "${home}/.local/share/pnpm/bin"
  ];
  basePath = lib.concatStringsSep ":" (systemPath ++ homePath);

  # Menu launches must run as a systemd service named app-gnome-steam@<x>, like
  # the autostart unit below: that name gives xdg-desktop-portal the app id
  # "steam", so the saved RemoteDesktop approval applies. A scope does not
  # work; Steam ends up back under gnome-shell's cgroup. -pipewire is the flag
  # the old hand-written steam.desktop passed.
  steamLauncher = pkgs.writeShellScript "steam-launcher" ''
    steam=/run/current-system/sw/bin/steam
    if systemctl --user --quiet is-active app-gnome-steam@autostart.service app-gnome-steam@desktop.service; then
      exec "$steam" "$@"
    fi
    exec systemd-run --user --quiet --collect --slice=app.slice \
      --unit=app-gnome-steam@desktop.service \
      -p Type=exec -p KillMode=process \
      "$steam" -pipewire "$@"
  '';
in
{
  xdg.desktopEntries.steam = {
    name = "Steam";
    comment = "Application for managing and playing games on Steam";
    exec = "${steamLauncher} %U";
    icon = "steam";
    terminal = false;
    categories = [
      "Network"
      "FileTransfer"
      "Game"
    ];
    mimeType = [
      "x-scheme-handler/steam"
      "x-scheme-handler/steamlink"
    ];
    settings.PrefersNonDefaultGPU = "true";
  };

  systemd.user.services = {
    # ~/Downloads/Tern-*/tern — remote session daemon. The session daemon it
    # spawns outlives the unit, hence KillMode=process. Not started at login:
    # start it with `systemctl --user start tern-remote`.
    tern-remote = {
      Unit = {
        Description = "Tern remote sessions (${user})";
        Documentation = [ "https://stencil.so" ];
        ConditionFileIsExecutable = "${home}/Downloads/Tern-0.6.3-linux-x86_64/tern/tern";
        StartLimitIntervalSec = 60;
        StartLimitBurst = 10;
      };
      Service = {
        Type = "exec";
        ExecStart = "${home}/Downloads/Tern-0.6.3-linux-x86_64/tern/tern remote serve --user --state-dir ${home}/.config/tern";
        Restart = "on-failure";
        RestartSec = 2;
        RestartPreventExitStatus = 2;
        KillMode = "process";
        TimeoutStopSec = 10;
      };
    };

    # Silent Steam at login. The unit name follows the systemd app naming
    # convention (app-<launcher>-<app id>@<instance>.service), which is how
    # xdg-desktop-portal learns the app id "steam". Started from
    # ~/.config/autostart, Steam ran inside gnome-session-manager@gnome.service
    # with no app id, so the portal could not remember the RemoteDesktop
    # ("remote control") approval the Steam Controller asks for.
    "app-gnome-steam@autostart" = {
      Unit = {
        Description = "Steam (silent autostart)";
        ConditionFileIsExecutable = "/run/current-system/sw/bin/steam";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "exec";
        ExecStart = "/run/current-system/sw/bin/steam -silent";
        # Steam re-execs itself; only the main process belongs to the unit.
        KillMode = "process";
        Slice = "app.slice";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    # ~/SteamControllerGyroDSU — prebuilt ELF binary, runs through nix-ld
    # (needs libhidapi-hidraw.so.0; see programs.nix-ld.libraries).
    SteamControllerGyroDSU = {
      Unit = {
        Description = "Steam Controller Gyro DSU Server";
        ConditionFileIsExecutable = "${home}/SteamControllerGyroDSU/SteamControllerGyroDSU";
        After = [ "sockets.target" ];
        StartLimitIntervalSec = 0;
      };
      Service = {
        Type = "simple";
        ExecStart = "${home}/SteamControllerGyroDSU/SteamControllerGyroDSU --port 26761";
        Restart = "always";
        RestartSec = 1;
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
