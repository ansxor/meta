# PipeASIO: an ASIO driver for Wine that talks to PipeWire directly (no JACK
# layer in between, unlike WineASIO). Built against `wine`, so pass the same
# Wine that will run it; the driver is registered per prefix with
# `pipeasio-register` and found at run time through WINEDLLPATH (the
# launcher in pkgs/fl-studio sets both). Not in nixpkgs.
{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  pipewire,
  pkgsCross,
  wine,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "pipeasio";
  version = "1.7.0";

  src = fetchFromGitHub {
    owner = "M0n7y5";
    repo = "pipeasio";
    tag = "v${finalAttrs.version}";
    hash = "sha256-L7EkqebKAgVtTWFDOH3b0emFE/3Esex8T0xtbOXjNgE=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    wine
    # The PE half is cross-compiled; winegcc looks for x86_64-w64-mingw32-gcc.
    pkgsCross.mingwW64.buildPackages.gcc
  ];

  buildInputs = [ pipewire ];

  cmakeFlags = [
    (lib.cmakeBool "BUILD_SETTINGS_PANEL" false) # Qt panel, unused inside Wine
    (lib.cmakeBool "BUILD_ARM64" false)
    (lib.cmakeBool "BUILD_TESTS" false)
    (lib.cmakeFeature "WINEBUILD" "${wine}/bin/winebuild")
    (lib.cmakeFeature "WINEGCC" "${wine}/bin/winegcc")
    (lib.cmakeFeature "WINE_INCLUDE_DIRS" "${wine}/include;${wine}/include/wine;${wine}/include/wine/windows")
    (lib.cmakeFeature "WINE_LIB_ROOT" "${wine}/lib/wine")
  ];

  meta = {
    description = "ASIO driver for Wine on top of PipeWire";
    homepage = "https://github.com/M0n7y5/pipeasio";
    license = lib.licenses.gpl3Plus;
    platforms = [ "x86_64-linux" ];
  };
})
