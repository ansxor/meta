{ config, pkgs, ... }:

let
  repo = "${config.home.homeDirectory}/Workspace/nix-config";
  omp = "${repo}/dotfiles/omp";

  # OMP rewrites its settings, plugin registry and mise config at runtime, so
  # everything here is an out-of-store link into the repo: edits made in OMP
  # land in dotfiles/omp and stay writable.
  link = path: config.lib.file.mkOutOfStoreSymlink path;
in
{
  home.file = {
    ".omp/agent/config.yml".source = link "${omp}/agent/config.yml";
    ".omp/agent/mcp.json".source = link "${omp}/agent/mcp.json";

    ".omp/agent/extensions/herdr-omp-agent-state.ts".source =
      link "${omp}/agent/extensions/herdr-omp-agent-state.ts";
    ".omp/agent/extensions/orca-agent-status.ts".source =
      link "${omp}/agent/extensions/orca-agent-status.ts";
    ".omp/agent/extensions/orca-prefill.ts".source = link "${omp}/agent/extensions/orca-prefill.ts";
    ".omp/agent/extensions/orca-titlebar-spinner.ts".source =
      link "${omp}/agent/extensions/orca-titlebar-spinner.ts";

    ".omp/agent/managed-skills/ratat-browser-smoke-login/SKILL.md".source =
      link "${omp}/agent/managed-skills/ratat-browser-smoke-login/SKILL.md";
    ".omp/agent/managed-skills/sbs2-react-message-list-rewrite/SKILL.md".source =
      link "${omp}/agent/managed-skills/sbs2-react-message-list-rewrite/SKILL.md";
    ".omp/agent/managed-skills/sbs2-react-port-diagnostics/SKILL.md".source =
      link "${omp}/agent/managed-skills/sbs2-react-port-diagnostics/SKILL.md";

    # Multi-file skill (SKILL.md + scripts/ + references/): link the directory.
    ".omp/agent/managed-skills/statechart".source = link "${omp}/agent/managed-skills/statechart";

    ".omp/plugins/omp-plugins.lock.json".source = link "${omp}/plugins/omp-plugins.lock.json";

    # Keep the mise global config writable so `mise use --global` still works.
    # This is also what installs oh-my-pi/omp on a fresh machine.
    ".config/mise/config.toml".source = link "${repo}/dotfiles/mise/config.toml";
  };

  # OMP (`oh-my-pi`, exposed as `omp`) and vanilla Pi (`pi`) are installed by
  # mise from dotfiles/mise/config.toml, not by nixpkgs. This installs them at
  # login when missing, so a fresh home needs no manual `mise install`. Only
  # these two are installed here; run `mise install` yourself for the other
  # tools in that file. A pinned version in the config is installed too; with
  # "latest", an existing install is kept until `mise upgrade`.
  systemd.user.services.mise-install-agents = {
    Unit = {
      Description = "Install OMP (oh-my-pi) and Pi with mise";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.mise}/bin/mise install --yes oh-my-pi pi";
      Restart = "on-failure";
      RestartSec = "30s";
      Environment = [
        "PATH=${
          pkgs.lib.makeBinPath [
            pkgs.coreutils
            pkgs.gnutar
            pkgs.gzip
            pkgs.xz
            pkgs.unzip
            pkgs.git
          ]
        }"
      ];
    };
    Install.WantedBy = [ "default.target" ];
  };
}
