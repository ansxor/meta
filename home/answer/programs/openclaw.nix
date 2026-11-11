{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

# OpenClaw gateway via nix-openclaw (systemd user unit openclaw-gateway,
# port 18789, state in ~/.openclaw). Nix owns ~/.openclaw/openclaw.json, so
# config changes go here, not through `openclaw config`/`openclaw plugins`.
# Local only: no chat channel; use the Control UI or the `openclaw` CLI.
let
  home = config.home.homeDirectory;

  # Claude Code is installed by mise (dotfiles/mise/config.toml); its login
  # lives in ~/.claude. The gateway's PATH only has runtimePackages, so expose
  # it through a shim that resolves the mise install instead of pinning a
  # second copy from nixpkgs.
  claude = pkgs.writeShellScriptBin "claude" ''
    exec ${pkgs.mise}/bin/mise exec claude-code -- claude "$@"
  '';
in
{
  imports = [ inputs.nix-openclaw.homeManagerModules.openclaw ];

  programs.openclaw = {
    enable = true;
    runtimePackages = [
      claude
      # chattr: OpenClaw marks its SQLite directories NOCOW on btrfs.
      pkgs.e2fsprogs
    ];

    # No workspace.bootstrapFiles: OpenClaw seeds AGENTS.md, SOUL.md, … in
    # ~/.openclaw/workspace and runs its first-run bootstrap interview; those
    # files stay runtime-owned and editable.

    config = {
      gateway = {
        mode = "local";
        auth = {
          mode = "token";
          token = {
            source = "file";
            provider = "gateway-token";
            id = "value";
          };
        };
      };

      # Read by both the gateway and the `openclaw` CLI. Must be a private
      # regular file (chmod 600), not a symlink.
      secrets.providers.gateway-token = {
        source = "file";
        path = "${home}/.secrets/openclaw-gateway-token";
        mode = "singleValue";
      };

      # Claude Code CLI backend (bundled anthropic plugin): Anthropic model refs
      # run through `claude` with its own login. Equivalent of
      # `openclaw models auth login --provider anthropic --method cli`, which
      # cannot write the Nix-owned config.
      agents.defaults = {
        model = "anthropic/claude-opus-5-5";
        models = {
          "anthropic/claude-opus-5-5".agentRuntime.id = "claude-cli";
          "anthropic/*".agentRuntime.id = "claude-cli";
        };
      };
    };
  };

  # The module's unit has no [Install] section, so it never started at login,
  # and it lacks the settings `openclaw gateway status` asks for (drain time
  # on stop, KillMode=mixed, network ordering).
  systemd.user.services.openclaw-gateway = {
    Unit = {
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      RestartSec = lib.mkForce "5s";
      KillMode = "mixed";
      TimeoutStopSec = 330;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
