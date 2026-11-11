{ inputs, pkgs, ... }:

{
  home.packages = with pkgs; [
    # ETS2 Local Radio: `ets2-local-radio` installs the plugin and runs the
    # server in the Proton prefix (see pkgs/ets2-local-radio).
    (callPackage ../../../../pkgs/ets2-local-radio/package.nix { })

    # BizHawk (`emuhawk-2_11_1-bin`, a prebuilt release; see pkgs/bizhawk).
    # Its own cores, including melonDS for the DS, ship in the release, so no
    # libretro cores are built. Add nixpkgs `libretro.*` cores here if needed.
    (import ../../../../pkgs/bizhawk/package.nix {
      inherit pkgs;
      src = inputs.bizhawk;
      libretroCores = [ ];
    })

    lutris
    heroic
    # JNativeHook in MCSR Fairplay dlopens these X libraries, which are not on
    # the wrapper's default library path (see its NEEDED list).
    (prismlauncher.override {
      additionalLibs = [
        libxtst
        libxt
        libxinerama
        libxkbcommon
        libx11
        libxcb
      ];
    })
    atlauncher
    protontricks
    mangohud
    goverlay
    mame
    cemu
    mgba
    mesen
    dwarf-fortress
    overlayed
    intiface-central
    sidequest
    wayvr
    opencomposite
    sunshine
    herdr
    handy
    kando
    protonup-qt
    vkbasalt
    vulkan-tools
    umu-launcher
    opentrack
    deadlock-mod-manager
    # Wrapper keeps ~/.local/share/Archipelago writable; see pkgs/archipelago.
    (callPackage ../../../../pkgs/archipelago/package.nix { })
    # Ship of Harkinian (`soh`). Needs your own OoT ROM on first launch to
    # generate oot.o2r in ~/.local/share/soh.
    shipwright
  ];
}
