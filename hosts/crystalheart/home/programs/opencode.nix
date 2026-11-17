{ config, ... }:

let
  repo = "${config.home.homeDirectory}/Workspace/nix-config";
  opencode = "${repo}/dotfiles/opencode";

  # OpenCode rewrites its CLI settings (theme, layout) in cli.json and plugins
  # may rewrite their own config, so these are out-of-store links into the repo
  # rather than read-only copies. The binary itself comes only from mise.
  link = path: config.lib.file.mkOutOfStoreSymlink path;
in
{
  xdg.configFile = {
    "opencode/opencode.json".source = link "${opencode}/opencode.json";
    "opencode/cli.json".source = link "${opencode}/cli.json";
    "opencode/oh-my-opencode-slim.json".source = link "${opencode}/oh-my-opencode-slim.json";
  };
}
