# Dev shell that builds the WiVRn headset client APK from the `wivrn` flake
# input (scripts/build-wivrn-apk.sh). Separate nixpkgs instance because the
# Android SDK/NDK are unfree and need the SDK licence accepted.
{ inputs, system }:
let
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      allowUnfree = true;
      android_sdk.accept_license = true;
    };
  };

  # Versions pinned by the fork's build.gradle (compileSdk, ndkVersion, cmake).
  sdk0 =
    (pkgs.androidenv.composeAndroidPackages {
      platformVersions = [ "34" ];
      buildToolsVersions = [ "35.0.0" ];
      includeNDK = true;
      ndkVersions = [ "29.0.14206865" ];
      cmakeVersions = [ "3.31.5" ];
    }).androidsdk;

  # The SDK's bundled ninja segfaults on NixOS; put nixpkgs' ninja in its
  # place. Everything else in the SDK is reused untouched via symlinks.
  sdk = pkgs.runCommand "android-sdk-ninja" { } ''
    root=libexec/android-sdk
    mkdir -p $out/$root
    for e in ${sdk0}/$root/*; do
      [ "$(basename $e)" = cmake ] || ln -s $e $out/$root/
    done
    mkdir -p $out/$root/cmake
    cp -rL ${sdk0}/$root/cmake/3.31.5 $out/$root/cmake/
    chmod -R u+w $out/$root/cmake
    ln -sf ${pkgs.ninja}/bin/ninja $out/$root/cmake/3.31.5/bin/ninja
  '';
in
pkgs.mkShell {
  packages = with pkgs; [
    gradle_8
    jdk17
    android-tools
    librsvg # rsvg-convert renders the launcher icon
    ktx-tools # toktx for the bundled textures
    glslang
    shaderc
    pkg-config
    git
    curl
    cmake
    ninja
  ];

  ANDROID_HOME = "${sdk}/libexec/android-sdk";
  JAVA_HOME = pkgs.jdk17.home;
  # The SDK's own aapt2 is patched for NixOS; Gradle's downloaded one is not.
  GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${sdk}/libexec/android-sdk/build-tools/35.0.0/aapt2";
  WIVRN_SRC = inputs.wivrn.outPath;
  WIVRN_REV = inputs.wivrn.rev or "local";
}
