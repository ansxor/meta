#!/usr/bin/env bash
# Activate the configuration on an installed NixOS or nix-darwin system.
set -euo pipefail
cd "$(dirname "$0")/.."

case "$(uname -s)" in
  Darwin)
    if command -v darwin-rebuild >/dev/null 2>&1; then
      exec sudo -H darwin-rebuild switch --flake .#macbook "$@"
    else
      exec sudo -H nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake .#macbook "$@"
    fi
    ;;
  *)
    exec sudo nixos-rebuild switch --flake .#crystalheart "$@"
    ;;
esac
