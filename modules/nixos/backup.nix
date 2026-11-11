{ ... }:

let
  home = "/home/answer";
in
{
  # Daily restic backup of /home to the SATA SSD (mounted at /mnt/backup in
  # hosts/crystalheart/disks.nix). Excludes what can be downloaded or rebuilt
  # again; Nextcloud is already on the server.
  services.restic.backups.home = {
    initialize = true;
    repository = "/mnt/backup/restic";
    passwordFile = "/etc/restic/password";
    paths = [ home ];
    exclude = [
      "${home}/.cache"
      "${home}/.local/share/Steam"
      "${home}/.local/share/Trash"
      "${home}/.local/share/baloo"
      "${home}/.local/share/flatpak"
      "${home}/.local/share/mise"
      "${home}/.local/share/pnpm"
      "${home}/.local/share/JetBrains"
      "${home}/.local/share/PrismLauncher/assets"
      "${home}/.local/share/PrismLauncher/libraries"
      "${home}/.local/share/PrismLauncher/meta"
      "${home}/.local/share/PrismLauncher/java"
      "${home}/.local/share/wineprefixes/*/drive_c/windows"
      "${home}/.var/app/*/cache"
      "${home}/.rustup"
      "${home}/.cargo/registry"
      "${home}/.npm"
      "${home}/go/pkg"
      "${home}/Nextcloud"
      "${home}/Downloads"
      "${home}/Games/Heroic"
      "${home}/Games/gog"
      "${home}/Games/umu"
      "${home}/Games/pso_wine"
      "**/node_modules"
    ];
    extraBackupArgs = [
      "--one-file-system"
      "--exclude-caches"
    ];
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
    ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };

  # Skip quietly until the backup disk is mounted and the password file
  # exists (docs/storage.md).
  systemd.services.restic-backups-home = {
    unitConfig = {
      ConditionPathIsMountPoint = "/mnt/backup";
      ConditionPathExists = "/etc/restic/password";
    };
    serviceConfig = {
      Nice = 19;
      IOSchedulingClass = "idle";
    };
  };
}
