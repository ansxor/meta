# answer's Nix config

Manages my desktop and Macbook. Maybe you'll find a fix to a thing you care about?

## What is here

```
flake.nix                     # inputs, crystalheart (NixOS) and macbook (nix-darwin)
checks.nix                    # `nix flake check`: formatting
wivrn-apk.nix                 # dev shell for building the WiVRn headset APK
hosts/crystalheart/
  default.nix                 # NixOS host composition
  hardware.nix                # CPU/GPU/Wi-Fi/audio/RGB/udev
  disks.nix                   # btrfs subvolumes + ESP
  home/                       # Home Manager profile for CrystalHeart
    packages/                 # apps: CLI, desktop, dev, gaming, media, Flatpaks
    programs/                 # fish, git, terminals, OMP, OpenClaw, user
                              # services, EasyEffects, ...
    dotfiles.nix              # Zellij/Fish/Nvim/Pi config links
hosts/macbook/
  default.nix                 # nix-darwin host composition
  home/                       # Home Manager profile for MacBook
    packages/                 # apps: CLI, dev, media
    programs/                 # fish, git, terminals, OMP, launchd user services
    dotfiles.nix              # Zellij/Fish/Nvim/Pi config links
modules/nixos/
  common.nix                  # users, locale, nix daemon, nix-ld
  boot.nix                    # GRUB, Zen kernel, zram, snapshots
  desktop.nix                 # Plasma (default), GNOME, GDM, GSConnect
  services.nix                # NetworkManager, Tailscale, Mullvad, Flatpak
  gaming.nix                  # Steam, WiVRn, Logitech wheel driver
  game-handoff.nix            # game-handoff service
  virtualisation.nix          # Docker, libvirt/QEMU (VirtualBox omitted)
  vfio.nix                    # opt-in GPU passthrough
modules/darwin/
  common.nix                  # primary user, Touch ID sudo, nix daemon, shells
  homebrew.nix                # declarative Homebrew taps, brews, casks
  system.nix                  # macOS system defaults
pkgs/                         # local packages not in nixpkgs
dotfiles/                     # copied user configs (no production secrets)
scripts/                      # check, switch, build-wivrn-apk
```

## Everyday use

```sh
./scripts/check.sh            # check formatting and evaluate the host config
nix fmt                       # format with the pinned nixfmt
./scripts/switch.sh           # nixos-rebuild / darwin-rebuild switch
mise install                  # other tools in dotfiles/mise (OMP, Pi and Claude Code install themselves)
```

Both hosts sign Git commits and tags with the same 1Password SSH key. On macOS, install 1Password in `/Applications` and enable its SSH agent. Remove any legacy `user.signingkey` override from `~/.gitconfig` so Home Manager's key takes effect.

Build without activating:

```sh
# NixOS (CrystalHeart)
nix build .#nixosConfigurations.crystalheart.config.system.build.toplevel -o result-system

# macOS (MacBook)
nix build .#darwinConfigurations.macbook.system -o result-system
```

New files must be tracked by git (`git add -N <file>`): the flake is evaluated
from the git tree and ignores untracked files.

LearnHarness applies a local GPT-6.2 Sol catalog patch to the upstream AppImage
at build time. The ChatGPT picker still only shows models reported by the
connected account. The package also backports the Codex prompt-caching fix for
[Pi #12273](https://github.com/earendil-works/pi/issues/12273). Drop each patch
once the bundled Pi version includes its change.

CrystalHeart disables Plasma's optional KDE PIM suite (KMail, Kontact, and
Merkuro) to avoid rebuilding mail and calendar packages when KRunner is patched.

For HDR with Steam Input on Plasma, run Proton through nested Gamescope on
XWayland. Leave `PROTON_ENABLE_WAYLAND` unset. The system enables Gamescope's
Vulkan WSI layer. In the game's Steam launch options:

```text
gamescope -f --hdr-enabled -e --virtual-connector-strategy SingleApplication -- %command%
```

`SingleApplication` goes after `-e` so the nested compositor selects the game
window instead of waiting for Steam to select it.

## Shared agent skills

On switch, Home Manager installs skills from `dotfiles/agents/skills/` for OMP,
Claude Code, Pi, OpenCode, Codex, and Antigravity, unless a skill's `meta.nix`
restricts its harnesses. Antigravity's App, IDE, and CLI share
`~/.gemini/config/skills/`. On CrystalHeart, launch the desktop app with
`antigravity` and view active skills under **Settings → Projects → Customizations**.

## Docs

- [Configuration harness](docs/config-harness.md)
- [FL Studio under Wine](docs/fl-studio.md)
- [Storage and backups](docs/storage.md)
