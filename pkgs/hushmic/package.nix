# HushMic: real-time microphone noise suppression as a PipeWire virtual mic.
# Prebuilt upstream release (same payload as the Arch hushmic-bin package,
# which also had no nixpkgs equivalent). The binary finds its LADSPA plugin,
# models and ONNX Runtime relative to its own prefix, so the install layout
# mirrors the tarball.
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  pipewire,
  wireplumber,
  gcc,
  libglvnd,
  wayland,
  libxkbcommon,
  libx11,
  libxcb,
  libxcursor,
  libxi,
  libxrender,
}:

stdenv.mkDerivation rec {
  pname = "hushmic";
  version = "0.11.0";

  src = fetchurl {
    url = "https://github.com/Fovty/hushmic/releases/download/v${version}/hushmic-${version}-x86_64.tar.gz";
    hash = "sha256-moyRVRwyWEU20neyO6kdjwO1X0HJOVfgMkhxapif2lM=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = [ gcc.cc.lib ];

  # The window code (winit + EGL/GL) dlopens these at run time, so
  # autoPatchelf cannot see them; without them the tray works but the
  # window fails with "winit EventLoopError".
  guiLibs = [
    libglvnd
    wayland
    libxkbcommon
    libx11
    libxcb
    libxcursor
    libxi
    libxrender
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r bin lib share $out/
    rm -rf $out/lib/systemd
    # Upstream's desktop entry already uses a bare `hushmic`.
    # The app shells out to pw-dump, pw-cli, pw-metadata, pw-record, pw-play
    # and pipewire (its own filter-chain host).
    wrapProgram $out/bin/hushmic \
      --prefix PATH : ${
        lib.makeBinPath [
          pipewire
          wireplumber
        ]
      } \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath guiLibs}
    runHook postInstall
  '';

  meta = {
    description = "Real-time microphone noise suppression as a PipeWire virtual mic (DPDFNet)";
    homepage = "https://github.com/Fovty/hushmic";
    license = with lib.licenses; [
      mit
      asl20
    ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "hushmic";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
