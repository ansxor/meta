{ config, ... }:

# macOS LaunchAgents that run user services from /Applications or $HOME.
let
  home = config.home.homeDirectory;
in
{
  launchd.agents = {
    # Tern's remote service: logs clients in and serves their session daemons
    # over QUIC (UDP 8376) and iroh.
    tern-remote = {
      enable = true;
      config = {
        ProgramArguments = [
          "/Applications/Tern.app/Contents/MacOS/tern"
          "remote"
          "serve"
          "--user"
          "--state-dir"
          "${home}/Library/Application Support/Tern"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        StandardErrorPath = "${home}/Library/Logs/tern-remote.log";
      };
    };

    codex-mimo-shim = {
      enable = true;
      config = {
        ProgramArguments = [
          "${home}/.local/share/codex-mimo-shim/run.sh"
        ];
        WorkingDirectory = "${home}/.local/share/codex-mimo-shim";
        RunAtLoad = true;
        KeepAlive = {
          SuccessfulExit = false;
        };
        StandardOutPath = "${home}/Library/Logs/codex-mimo-shim.out.log";
        StandardErrorPath = "${home}/Library/Logs/codex-mimo-shim.err.log";
      };
    };

    tutabridge = {
      enable = true;
      config = {
        ProgramArguments = [
          "${home}/.local/bin/tutabridge"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "${home}/Library/Logs/tutabridge.log";
        StandardErrorPath = "${home}/Library/Logs/tutabridge.error.log";
      };
    };
  };
}
