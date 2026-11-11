#!/usr/bin/env bash
# Evaluate the configuration and run the flake checks without building the
# whole system. Format with `nix fmt` if the formatting check fails.
set -euo pipefail

cd "$(dirname "$0")/.."

case "$(uname -s)" in
  Darwin)
    # `nix flake check` evaluates nixosConfigurations.crystalheart, which
    # fetches the CrystalHeart-local `game-handoff` repo (`/home/answer/...`).
    # On macOS, check formatting and evaluate darwinConfigurations.macbook directly.
    echo "==> checks.aarch64-darwin.formatting"
    nix build .#checks.aarch64-darwin.formatting --no-link
    echo "==> evaluate darwinConfigurations.macbook"
    nix eval .#darwinConfigurations.macbook.config.system.build.toplevel.drvPath >/dev/null
    ;;
  *)
    echo "==> nix flake check (evaluation, formatting)"
    nix flake check
    echo "==> evaluate darwinConfigurations.macbook"
    nix eval .#darwinConfigurations.macbook.config.system.build.toplevel.drvPath >/dev/null
    ;;
esac
