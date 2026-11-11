# answer's Nix config

Manages my desktop and Macbook. Maybe you'll find a fix to a thing you care about?

## What is here

```
flake.nix                     # inputs and the crystalheart system
checks.nix                    # `nix flake check`: formatting
wivrn-apk.nix                 # dev shell for building the WiVRn headset APK
hosts/crystalheart/
  default.nix                 # host composition
  hardware.nix                # CPU/GPU/Wi-Fi/audio/RGB/udev
  disks.nix                   # btrfs subvolumes + ESP
modules/nixos/
  common.nix                  # users, locale, nix daemon, nix-ld
  boot.nix                    # GRUB, Zen kernel, zram, snapshots
  desktop.nix                 # GNOME, GSConnect
  services.nix                # NetworkManager, Tailscale, Mullvad, Flatpak
  gaming.nix                  # Steam, WiVRn, Logitech wheel driver
  game-handoff.nix            # game-handoff service
  virtualisation.nix          # Docker, libvirt/QEMU (VirtualBox omitted)
  vfio.nix                    # opt-in GPU passthrough
home/answer/                  # Home Manager profile
  packages/                   # apps: CLI, desktop, dev, gaming, media, Flatpaks
  programs/                   # fish, git, terminals, OMP, OpenClaw, user
                              # services, EasyEffects, ...
  dotfiles.nix                # Zellij/Fish/Nvim config links
pkgs/                         # local packages not in nixpkgs
dotfiles/                     # copied user configs (no production secrets)
scripts/                      # check, switch, build-wivrn-apk
```

## Everyday use

```sh
./scripts/check.sh            # nix flake check (evaluation, formatting)
nix fmt                       # format with the pinned nixfmt
./scripts/switch.sh           # nixos-rebuild switch; also installs Flatpaks
mise install                  # other tools in dotfiles/mise (OMP, Pi and Claude Code install themselves)
```

Build without activating:

```sh
nix build .#nixosConfigurations.crystalheart.config.system.build.toplevel -o result-system
```

New files must be tracked by git (`git add -N <file>`): the flake is evaluated
from the git tree and ignores untracked files.

## Docs

- [Configuration harness](docs/config-harness.md)
- [FL Studio under Wine](docs/fl-studio.md)
- [Storage and backups](docs/storage.md)
