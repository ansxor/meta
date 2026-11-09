#!/usr/bin/env bash
# Build the WiVRn headset client APK from the pinned `wivrn` flake input.
#   scripts/build-wivrn-apk.sh            build only
#   scripts/build-wivrn-apk.sh HOST:PORT  build, then `adb connect` + install
# Output: ~/.cache/wivrn-apk/WiVRn.apk. The signing key lives in
# ~/.local/share/wivrn-apk so later builds install over earlier ones.
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
if [ -z "${WIVRN_SRC:-}" ]; then
  exec nix develop "$repo#wivrn-apk" -c "$0" "$@"
fi

work=$HOME/.cache/wivrn-apk
keydir=$HOME/.local/share/wivrn-apk
mkdir -p "$work" "$keydir"

# The store copy is read-only; Gradle needs a writable tree.
rm -rf "$work/src"
cp -r "$WIVRN_SRC" "$work/src"
chmod -R u+w "$work/src"
cd "$work/src"

# The version is read from git; the store copy has no .git.
git init -q
git add -A
git -c commit.gpgsign=false -c user.name=wivrn-apk -c user.email=wivrn-apk@localhost commit -q -m "${WIVRN_REV:-local}"

if [ ! -f "$keydir/ks.keystore" ]; then
  umask 077
  head -c 24 /dev/urandom | base64 | tr -d '/+=' > "$keydir/password"
  keytool -genkey -keystore "$keydir/ks.keystore" -alias default_key \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -storepass "$(cat "$keydir/password")" -keypass "$(cat "$keydir/password")" \
    -dname "CN=WiVRn local build"
fi
cp "$keydir/ks.keystore" ks.keystore
echo "signingKeyPassword=$(cat "$keydir/password")" > gradle.properties
echo "fetchcontent_base_dir=$work/fetchcontent" >> gradle.properties

gradle --no-daemon assembleRelease
apk=$(find build/outputs/apk/release -name '*.apk' | head -1)
cp "$apk" "$work/WiVRn.apk"
echo "APK: $work/WiVRn.apk"

if [ $# -ge 1 ]; then
  adb connect "$1"
  adb -s "$1" install -r "$work/WiVRn.apk"
fi
