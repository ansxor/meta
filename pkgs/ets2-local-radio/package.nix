# ETS2/ATS Local Radio (https://github.com/Koenvh1/ets2-local-radio): a
# Windows .NET server plus a telemetry plugin DLL. Both run for the Proton
# build of Euro Truck Simulator 2, so the command below installs the plugin
# into the game and starts the server inside the game's Proton prefix.
# Requires ETS2 to run through Proton (Steam > Properties > Compatibility),
# launched once so compatdata/227300 and bin/win_x64 exist.
{
  lib,
  stdenvNoCC,
  fetchurl,
  p7zip,
  writeShellApplication,
  rsync,
  proton-ge-bin,
}:

let
  version = "4.1.0";
  app = stdenvNoCC.mkDerivation {
    pname = "ets2-local-radio-files";
    inherit version;
    src = fetchurl {
      url = "https://github.com/Koenvh1/ets2-local-radio/releases/download/v${version}/Local.Radio.7z";
      hash = "sha256-+J4qOl5v9q+ynsIJ5FBoXhEeKGZNA0yApWC+JuDwcQY=";
    };
    nativeBuildInputs = [ p7zip ];
    unpackPhase = "7z x $src";
    installPhase = ''
      mkdir -p $out
      cp -r "ETS2 Local Radio"/. $out/
    '';
  };
in
writeShellApplication {
  name = "ets2-local-radio";
  runtimeInputs = [ rsync ];
  meta = {
    description = "ETS2/ATS Local Radio server and plugin installer for Proton";
    homepage = "https://github.com/Koenvh1/ets2-local-radio";
    license = lib.licenses.gpl3Plus;
    platforms = [ "x86_64-linux" ];
    mainProgram = "ets2-local-radio";
  };
  text = ''
    steam=''${STEAM_ROOT:-$HOME/.local/share/Steam}
    game="$steam/steamapps/common/Euro Truck Simulator 2"
    prefix="$steam/steamapps/compatdata/227300"
    home=''${XDG_DATA_HOME:-$HOME/.local/share}/ets2-local-radio

    if [ ! -d "$prefix/pfx" ] || [ ! -d "$game/bin/win_x64" ]; then
      echo "ETS2 has no Proton prefix yet. Set Steam > Euro Truck Simulator 2 >" >&2
      echo "Properties > Compatibility to a Proton version, launch the game once, then retry." >&2
      exit 1
    fi

    # Plugin DLL into the game (idempotent; refreshed on every run).
    mkdir -p "$game/bin/win_x64/plugins"
    install -m644 ${app}/plugins/bin/win_x64/plugins/local-radio.dll "$game/bin/win_x64/plugins/"

    # The server writes settings next to itself, so it runs from a writable
    # copy; user files (web/custom.js, settings) survive updates.
    mkdir -p "$home"
    rsync -a --chmod=u+w --exclude custom.js --exclude 'settings*' ${app}/ "$home"/
    cd "$home"

    export STEAM_COMPAT_DATA_PATH="$prefix"
    export STEAM_COMPAT_CLIENT_INSTALL_PATH="$steam"
    exec ${proton-ge-bin.steamcompattool}/proton run "$home/ETS2 Local Radio server.exe"
  '';
}
