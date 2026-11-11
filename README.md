# CrystalHeart — NixOS configuration

NixOS configuration for the desktop formerly running Arch Linux, with a Home
Manager profile for the `answer` user.

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

## Packages that are not in nixpkgs

Local packages live in `pkgs/` and are added in `home/answer/packages/` or the
NixOS modules: Archipelago (writable data-dir wrapper), BizHawk, Claude
Desktop, ETS2 Local Radio, FL Studio (launcher and PipeASIO; Wine 11.21 from a pinned second nixpkgs), Helium, HushMic and the `hid-logitech-dd` kernel module.

Other packages come from external flakes, because nixpkgs doesn't have them:

- Zen Browser, from `github:youwen5/zen-browser-flake`;
- Time Timer (libadwaita), from
  `git+https://tangled.org/ansxor.ca/time-timer-adwaita`;
- WiVRn (fork), from `git+https://git.shsbs.xyz/ansxor/wivrn`;
- the Logitech TrueForce driver, from
  `github:mescon/logitech-trueforce-linux-driver`;
- BizHawk's own Nix expression, from `github:TASEmulators/BizHawk`;
- a second, pinned nixpkgs for Wine 11.21 (`nixpkgs-wine`), used only by FL Studio.

Flatpaks are declared with nix-flatpak in `home/answer/packages/flatpaks.nix`.

## Known gaps

- No CachyOS BORE-LTO kernel: nix-cachyos-kernel's binary cache is offline,
  so the config uses Zen plus `scx_lavd` and the CachyOS `ananicy-cpp` rules.
- Secrets, SSH/GPG keys, and app data stay in the preserved `/home`; only
  non-secret dotfiles and local test fixtures are in `dotfiles/`.
- VirtualBox host support is omitted; nixpkgs VirtualBox 7.2.20 fails to build
  with `-Werror` in this revision. Use libvirt/QEMU.

## Docs

- [Configuration harness](docs/config-harness.md)
- [FL Studio under Wine](docs/fl-studio.md)
- [Storage and backups](docs/storage.md)
