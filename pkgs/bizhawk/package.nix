# BizHawk (EmuHawk) 2.11.1 from upstream's own Nix expression, using the
# prebuilt release (`emuhawk-latest-bin`). Not in nixpkgs.
#
# Upstream compiles every license-compatible libretro core by default, which
# is a very long build for a feature few people use (BizHawk's own cores
# ship in the release). `libretroCores` picks the ones to build instead.
{
  pkgs,
  src,
  libretroCores ? [ ],
}:

let
  inherit (pkgs) lib;

  libretroDeps = pkgs.symlinkJoin {
    name = "bizhawk-unmanaged-deps-libretro";
    # Same repackaging as upstream's Dist/packages-libretro.nix: only the
    # core's shared library, under its libretro path.
    paths = map (
      drv:
      drv.overrideAttrs (
        oldAttrs:
        if oldAttrs ? includeRetroArch then
          { includeRetroArch = false; }
        else
          {
            installPhase = ''
              runHook preInstall
              install -Dt "${builtins.placeholder "out"}${oldAttrs.passthru.libretroCore}" *${drv.stdenv.hostPlatform.extensions.sharedLibrary}
              runHook postInstall
            '';
          }
      )
    ) libretroCores;
  };

  emuhawk =
    (import src {
      inherit pkgs;
      system = pkgs.stdenv.hostPlatform.system;
      libretroCores = libretroDeps;
    }).emuhawk-latest-bin;

  desktopItem = pkgs.makeDesktopItem {
    name = "bizhawk";
    desktopName = "BizHawk";
    genericName = "Emulator";
    comment = "Multi-system emulator with TAS tools and Lua scripting";
    exec = "${emuhawk.meta.mainProgram or "emuhawk-monort-2.11.1"} %f";
    icon = "bizhawk";
    categories = [
      "Game"
      "Emulator"
    ];
    startupWMClass = "EmuHawk.exe";
  };
in
# Upstream's own entry is a bare "EmuHawk (Mono Runtime)" with an icon name
# that doesn't exist; replace it with a proper one using the logo from the
# source tree.
pkgs.symlinkJoin {
  name = "bizhawk-${emuhawk.version or "2.11.1"}";
  paths = [ emuhawk ];
  nativeBuildInputs = [
    pkgs.icoutils
    pkgs.makeWrapper
  ];
  postBuild = ''
    # SDL hides the Steam Controller's virtual gamepad from apps unless told
    # otherwise (same variable as the melonDS Flatpak override).
    for bin in $out/bin/*; do
      target=$(readlink -f "$bin")
      rm "$bin"
      makeWrapper "$target" "$bin" \
        --set-default SDL_GAMECONTROLLER_ALLOW_STEAM_VIRTUAL_GAMEPAD 1
    done
    rm -f $out/share/applications/*.desktop
    install -Dm644 ${desktopItem}/share/applications/bizhawk.desktop \
      $out/share/applications/bizhawk.desktop
    mkdir icons
    icotool -x -o icons ${src}/src/BizHawk.Client.EmuHawk/images/logo.ico
    for f in icons/*.png; do
      size=$(basename "$f" | sed -E 's/.*_([0-9]+)x[0-9]+x[0-9]+\.png/\1/')
      install -Dm644 "$f" "$out/share/icons/hicolor/''${size}x''${size}/apps/bizhawk.png"
    done
  '';
  meta = emuhawk.meta or { };
}
