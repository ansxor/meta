# Storage

Three drives, split by what losing them would cost.

| Drive | Mount | Holds |
|---|---|---|
| Samsung 980 PRO 2 TB (NVMe) | `/`, `/nix`, `/home`, `/efi` | The system and everything irreplaceable. btrfs, subvolumes in `hosts/crystalheart/disks.nix`. |
| Samsung 990 PRO 2 TB (NVMe) | `/mnt/games` | The Steam library and other data that can be downloaded again. ext4, label `games`. |
| Seagate BarraCuda 500 GB (SATA) | `/mnt/backup` | The restic repository for `/home`. ext4, label `backup`. |

Both extra drives mount by label with `nofail`: the machine boots without them,
and nothing the system needs lives on either.

## Preparing a drive

Address drives by `/dev/disk/by-id`, never `nvme0n1`: those names can swap
between boots. Check the target with `lsblk -o NAME,SIZE,MODEL,FSTYPE` first.

```fish
set dev /dev/disk/by-id/nvme-Samsung_SSD_990_PRO_2TB_S7L9NJ0Y414773J
sudo blkdiscard -f $dev
sudo sgdisk -n1:0:0 -t1:8300 -c1:games $dev
sudo udevadm settle
sudo mkfs.ext4 -L games -m 0 $dev-part1
```

For the SATA drive use its `ata-Seagate_BarraCuda_SSD_ZA500CM10002_7M002ADG` ID,
the label `backup` and the partition name `backup`.

## Steam

In Steam, Settings → Storage → add `/mnt/games`, then move installed games with
the Move button and make the new drive the default. Proton prefixes sit in each
library's `steamapps/compatdata`, so they move with the games; check one game's
prefix after the first move.

## Backups

`modules/nixos/backup.nix` runs `restic-backups-home` daily at a random time in
the hour after midnight. The first run needs a repository password, created
once:

```fish
sudo install -d -m 700 /etc/restic
head -c 32 /dev/urandom | base64 | sudo tee /etc/restic/password >/dev/null
sudo chmod 600 /etc/restic/password
sudo cat /etc/restic/password
```

Keep a copy of that password in 1Password: without it the repository cannot be
read. Until the file and the mounted drive both exist, the service skips
silently.

```fish
sudo systemctl start restic-backups-home      # run now
journalctl -u restic-backups-home -f

sudo restic -r /mnt/backup/restic --password-file /etc/restic/password snapshots
sudo restic -r /mnt/backup/restic --password-file /etc/restic/password \
  restore latest --target ~/restored --include /home/answer/Documents
```

What is excluded is the `exclude` list in `backup.nix`: caches, Steam,
Flatpak and mise installs, Nextcloud (it lives on the server), Downloads, and
the reinstallable parts of `~/Games`. Retention is 7 daily, 4 weekly and
6 monthly snapshots. The backup lives in the same machine, so it covers a
failed drive, not theft or fire.
