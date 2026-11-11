{ ... }:

# Declarative Homebrew for Mac-specific taps, formulae, and casks.
# Switches only install missing entries (`cleanup = "none"`), leaving apps and
# formulae installed by hand untouched.
{
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "none";
    };

    taps = [
      "d12frosted/emacs-plus"
      "dmtrkovalenko/fff"
      "docker/tap"
      "modem-dev/tap"
      "openclaw/tap"
      "polytoken/tap"
      "renode/tap"
      "routatic/tap"
      "runpod/runpodctl"
      "steipete/tap"
      "xdevplatform/tap"
    ];

    brews = [
      "agent-browser"
      "cliclick"
      "dmtrkovalenko/fff/fff-mcp"
      "gascity"
      "lexbor"
      "libgccjit"
      "mlx"
      "modem-dev/tap/hunk"
      "openclaw/tap/gogcli"
      "polytoken/tap/polytoken"
      "routatic/tap/routatic-proxy"
      "runpod/runpodctl/runpodctl"
      "steipete/tap/birdclaw"
      "steipete/tap/spogo"
      "tailscale"
      "virtualenv"
    ];

    casks = [
      "1password-cli"
      "android-commandlinetools"
      "android-platform-tools"
      "codexbar"
      "dotnet-sdk"
      "emacs-plus-app"
      "sbx"
      "tailscale-app"
      "xurl"
    ];
  };
}
