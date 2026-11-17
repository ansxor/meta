{ config, ... }:

let
  repo = "${config.home.homeDirectory}/Workspace/nix-config";
  claude = "${repo}/dotfiles/claude";

  # Claude Code and the herdr hooks rewrite settings.json at runtime, so
  # these are out-of-store links: edits land in dotfiles/claude. Credentials,
  # history, plugins and skills (see modules/home/agent-skills.nix) stay out of this file.
  link = path: config.lib.file.mkOutOfStoreSymlink path;
in
{
  home.file = {
    ".claude/settings.json".source = link "${claude}/settings.json";
    ".claude/CLAUDE.md".source = link "${claude}/CLAUDE.md";
    ".claude/agents".source = link "${claude}/agents";
  };
}
