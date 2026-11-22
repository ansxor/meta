{ ... }:

{
  programs.git = {
    enable = true;
    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKtsAmcwmQ6Oa6Z8nl2n+zM5ML3XZTGAjIVHF6gqgfHq";
      signByDefault = true;
      format = "ssh";
      signer = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
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

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  programs.lazygit.enable = true;
}
