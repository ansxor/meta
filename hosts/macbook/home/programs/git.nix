{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    signing = {
      key = "60E28B11C5B1F588!";
      signByDefault = true;
      format = "openpgp";
    };
    settings = {
      user = {
        name = "ansxor";
        email = "git@ansxor.ca";
      };
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      tag.gpgsign = true;
      credential.helper = "osxkeychain";
      beads.role = "maintainer";
    };
  };

  programs.gpg.enable = true;

  # GUI passphrase prompt for macOS (git commit/tag signing). Home Manager
  # runs gpg-agent as a socket-activated launchd user agent with pinentry-mac.
  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry_mac;
  };

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  programs.lazygit.enable = true;
}
