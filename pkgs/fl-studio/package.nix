# FL Studio launcher and prefix manager (Wine 11.21, passed in as `wine`).
#
# FL Studio itself is proprietary and not redistributable, so this package
# ships no copy of it: download Image-Line's Windows installer yourself and run
# `fl-studio install flstudio_win64_*.exe`. That creates a writable Wine
# prefix in ~/.local/share/wineprefixes/flstudio (never in the store), installs
# the fonts and C++ runtime plugins need, registers the PipeASIO driver and
# applies the registry settings from https://pr1v8.ca/posts/fl-studio-wine-plugins-ilok/
# that apply to stock Wine.
{
  lib,
  stdenvNoCC,
  replaceVars,
  makeWrapper,
  makeDesktopItem,
  bash,
  coreutils,
  findutils,
  gnugrep,
  procps,
  cabextract,
  curl,
  unzip,
  icoutils,
  winetricks,
  wine,
  pipeasio,
}:

let
  desktopItem = makeDesktopItem {
    name = "fl-studio";
    desktopName = "FL Studio";
    genericName = "Digital Audio Workstation";
    comment = "Image-Line FL Studio, running under Wine";
    exec = "fl-studio %U";
    icon = "fl-studio";
    categories = [
      "AudioVideo"
      "Audio"
      "Midi"
      "Sequencer"
    ];
    mimeTypes = [ "x-scheme-handler/flstudio" ];
    startupWMClass = "fl64.exe";
  };
in
stdenvNoCC.mkDerivation {
  pname = "fl-studio";
  version = "0-launcher";

  dontUnpack = true;
  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    install -Dm755 ${
      replaceVars ./fl-studio.sh {
        inherit wine pipeasio;
      }
    } $out/bin/fl-studio
    patchShebangs $out/bin/fl-studio
    wrapProgram $out/bin/fl-studio --prefix PATH : ${
      lib.makeBinPath [
        bash
        coreutils
        findutils
        gnugrep
        procps
        cabextract
        curl
        unzip
        icoutils
        winetricks
      ]
    }

    mkdir -p $out/share/applications
    cp ${desktopItem}/share/applications/*.desktop $out/share/applications/
    substituteInPlace $out/share/applications/fl-studio.desktop \
      --replace-fail "Exec=fl-studio" "Exec=$out/bin/fl-studio"

    runHook postInstall
  '';

  meta = {
    description = "FL Studio launcher and Wine prefix setup (the program itself is not included)";
    homepage = "https://www.image-line.com/fl-studio";
    license = lib.licenses.unfree;
    mainProgram = "fl-studio";
    platforms = [ "x86_64-linux" ];
  };
}
