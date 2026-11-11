{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    signing = {
      key = "38EF7512C7FE469F";
      signByDefault = true;
      format = "openpgp";
    };
    settings = {
      user = {
        name = "darienreese";
        email = "git@darienreese.ca";
      };
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      tag.gpgsign = true;
      credential.helper = "store";
    };
  };

  programs.gpg.enable = true;

  # GUI passphrase prompt for GNOME (git commit/tag signing). Home Manager
  # runs gpg-agent as a socket-activated user service with this pinentry.
  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-gnome3;
  };

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  programs.lazygit.enable = true;
}
