# Helium (ungoogled-Chromium based browser), prebuilt upstream Linux release
# from https://github.com/imputnet/helium-linux. Not in nixpkgs. Same payload
# as the AUR helium-browser-bin package this replaces. The release is
# Chromium built against a generic distro, so libraries are patched in with
# autoPatchelfHook; the Qt shims are optional and left unresolved.
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  wrapGAppsHook3,
  alsa-lib,
  at-spi2-core,
  cairo,
  cups,
  dbus,
  expat,
  glib,
  gsettings-desktop-schemas,
  gtk3,
  libdrm,
  libgbm,
  libglvnd,
  libnotify,
  libsecret,
  libuuid,
  libva,
  libx11,
  libxcb,
  libxcomposite,
  libxcursor,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxkbcommon,
  libxrandr,
  libxrender,
  libxscrnsaver,
  libxtst,
  nspr,
  nss,
  pango,
  pciutils,
  pipewire,
  systemd,
  vulkan-loader,
  wayland,
  xdg-utils,
}:

let
  # dlopen'ed at runtime, so invisible to autoPatchelfHook.
  runtimeLibs = [
    libglvnd
    libnotify
    libsecret
    libva
    pipewire
    systemd
    vulkan-loader
    wayland
  ];
in
stdenv.mkDerivation rec {
  pname = "helium";
  version = "0.20.3.1";

  src = fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64_linux.tar.xz";
    hash = "sha256-N1nqTpW/TvSgpkd+PXNXaw8DkG8ugDVydb/Gysr7X6w=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook3
  ];

  buildInputs = [
    alsa-lib
    at-spi2-core
    cairo
    cups
    dbus
    expat
    glib
    gsettings-desktop-schemas
    gtk3
    libdrm
    libgbm
    libuuid
    libx11
    libxcb
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxkbcommon
    libxrandr
    libxrender
    libxscrnsaver
    libxtst
    nspr
    nss
    pango
    stdenv.cc.cc.lib
  ]
  ++ runtimeLibs;

  # Optional toolkit integration; only loaded when Qt is present.
  autoPatchelfIgnoreMissingDeps = [
    "libQt5*"
    "libQt6*"
  ];

  dontConfigure = true;
  dontBuild = true;
  # The browser binary is already stripped; stripping would only slow the build.
  dontStrip = true;
  dontWrapGApps = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt $out/bin $out/share/applications $out/share/icons/hicolor/256x256/apps
    cp -r . $out/opt/helium
    install -Dm644 helium.desktop $out/share/applications/helium.desktop
    install -Dm644 product_logo_256.png $out/share/icons/hicolor/256x256/apps/helium.png
    substituteInPlace $out/share/applications/helium.desktop \
      --replace-fail "Exec=helium" "Exec=$out/bin/helium"

    runHook postInstall
  '';

  postFixup = ''
    makeWrapper $out/opt/helium/helium $out/bin/helium \
      "''${gappsWrapperArgs[@]}" \
      --set CHROME_WRAPPER helium \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibs} \
      --prefix PATH : ${
        lib.makeBinPath [
          xdg-utils
          pciutils
        ]
      }
  '';

  meta = {
    description = "Privacy-focused Chromium-based web browser";
    homepage = "https://helium.computer";
    license = lib.licenses.gpl3Only;
    mainProgram = "helium";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
