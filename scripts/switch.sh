#!/usr/bin/env bash
# Activate the configuration on an installed NixOS system.
set -euo pipefail
cd "$(dirname "$0")/.."
exec sudo nixos-rebuild switch --flake .#crystalheart "$@"
