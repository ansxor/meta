# nixpkgs' Archipelago with a launch-time fix for read-only user data.
#
# The install dir is in the Nix store, so on first run after a new release
# Archipelago's Utils.user_path copies Players/, data/sprites, data/lua and
# manifest.json into ~/.local/share/Archipelago with shutil.copytree/copy2,
# which keep the store's read-only modes (and its 1970 mtimes). Players/ then
# can't hold new YAMLs. The wrapper does that same sync itself, writable, just
# before launching; the app then sees an identical manifest.json and skips its
# own copy. It also repairs modes left by earlier runs.
{
  archipelago,
  coreutils,
  diffutils,
  writeShellScript,
}:

let
  syncUserData = writeShellScript "archipelago-sync-user-data" ''
    export PATH=${coreutils}/bin:${diffutils}/bin
    app=$1
    user="$HOME/.local/share/Archipelago"

    mkdir -p "$user"
    chmod -R u+w "$user" 2>/dev/null || true

    if ! cmp -s "$app/manifest.json" "$user/manifest.json"; then
      for dir in Players data/sprites data/lua; do
        mkdir -p "$user/$dir"
        cp -rT --no-preserve=mode,ownership,timestamps "$app/$dir" "$user/$dir"
      done
      cp --no-preserve=mode,ownership,timestamps "$app/manifest.json" "$user/manifest.json"
      chmod -R u+w "$user" 2>/dev/null || true
    fi
  '';
in
archipelago.overrideAttrs (old: {
  postInstall = (old.postInstall or "") + ''
    wrapProgram $out/bin/archipelago \
      --run "${syncUserData} $out/lib/opt/Archipelago"
  '';
})
