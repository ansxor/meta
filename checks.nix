# Cheap checks for `nix flake check`. The full system build is in
# scripts/check.sh.
{ self, pkgs }:
{
  formatting = pkgs.runCommand "check-formatting" { nativeBuildInputs = [ pkgs.nixfmt ]; } ''
    find ${self} -name '*.nix' -type f -print0 | xargs -0 nixfmt --check
    touch $out
  '';
}
