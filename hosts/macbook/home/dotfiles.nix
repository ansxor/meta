{ config, ... }:

let
  repo = "${config.home.homeDirectory}/Workspace/meta/dotfiles";
in
{
  xdg.configFile = {
    # Zellij
    "zellij/config.kdl".source = ../../../dotfiles/zellij/config.kdl;

    # Fish customizations that are not provided by fishPlugins.
    "fish/functions/loadenv.fish".source = ../../../dotfiles/fish/functions/loadenv.fish;
    "fish/functions/jj-search.fish".source = ../../../dotfiles/fish/functions/jj-search.fish;
    "fish/functions/deno-doc-npm.fish".source = ../../../dotfiles/fish/functions/deno-doc-npm.fish;
    "fish/functions/deno-doc-npm-render.jq".source =
      ../../../dotfiles/fish/functions/deno-doc-npm-render.jq;
    "fish/conf.d/fish_frozen_theme.fish".source = ../../../dotfiles/fish/conf.d/fish_frozen_theme.fish;
    "fish/conf.d/moonbit.fish".source = ../../../dotfiles/fish/conf.d/moonbit.fish;

    # LazyVim writes lazy-lock.json, so point at the repo instead of the store.
    # The repo must be cloned at this path on the installed system.
    "nvim".source = config.lib.file.mkOutOfStoreSymlink "${repo}/nvim";
  };

  # Pi coding agent — tracked config files symlinked so Pi can write updates
  # (lastChangelogVersion, trust additions) back to the repo.
  # models.json holds no secrets (local endpoints only); a remote provider's
  # key belongs there as `!op read op://...`, which Pi resolves through the
  # 1Password CLI. auth.json (OAuth tokens Pi rewrites) stays local and
  # gitignored; see auth.json.template.
  home.file = {
    ".pi/agent/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${repo}/pi/settings.json";
    ".pi/agent/models.json".source = config.lib.file.mkOutOfStoreSymlink "${repo}/pi/models.json";
    ".pi/agent/trust.json".source = config.lib.file.mkOutOfStoreSymlink "${repo}/pi/trust.json";
    ".pi/agent/extensions".source = config.lib.file.mkOutOfStoreSymlink "${repo}/pi/extensions";
    ".pi/agent/skills".source = config.lib.file.mkOutOfStoreSymlink "${repo}/pi/skills";
    ".pi/agent/prompts".source = config.lib.file.mkOutOfStoreSymlink "${repo}/pi/prompts";
    ".pi/agent/themes".source = config.lib.file.mkOutOfStoreSymlink "${repo}/pi/themes";
  };
}
