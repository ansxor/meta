#!/usr/bin/env bash
# Evaluate the configuration and run the flake checks without building the
# whole system. Format with `nix fmt` if the formatting check fails.
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> nix flake check (evaluation, formatting)"
nix flake check
