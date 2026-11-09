# Claude Desktop (Electron), official Linux build from Anthropic's apt
# repository (https://downloads.claude.ai/claude-desktop/apt/stable). Not in
# nixpkgs. The .deb is installed verbatim; its maintainer scripts do the
# Debian-only parts, which are skipped here: AppArmor profile, apt source,
# GNOME Shell search provider, /usr/bin/ccd link and MIME registration.
{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  alsa-lib,
  at-spi2-core,
  cairo,
  cups,
  dbus,
  expat,
  glib,
  gtk3,
  libappindicator-gtk3,
  libcap_ng,
  libdrm,
  libgbm,
  libglvnd,
  libnotify,
  libsecret,
  libseccomp,
  libuuid,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  libxtst,
  nspr,
  nss,
  pipewire,
  pango,
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
    libappindicator-gtk3
    systemd
    vulkan-loader
    wayland
  ];
in
stdenv.mkDerivation rec {
  pname = "claude-desktop";
  version = "4.4212.0";

  src = fetchurl {
    url = "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_${version}_amd64.deb";
    hash = "sha256-T89ljg/IlTkKuCWTKHKB37ziYbDsPqkAYOgti/v9eoQ=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    alsa-lib
    at-spi2-core
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    libcap_ng
    libdrm
    libgbm
    libseccomp
    libuuid
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxkbcommon
    libxrandr
    libxtst
    nspr
    nss
    pipewire
    pango
    stdenv.cc.cc.lib
  ]
  ++ runtimeLibs;

  # chrome-sandbox is setuid, which tar cannot restore in the build sandbox.
  unpackPhase = "dpkg-deb --fsys-tarfile $src | tar -x --no-same-permissions --no-same-owner";

  dontConfigure = true;
  dontBuild = true;
  # Electron's asar and bundled binaries must stay byte-identical.
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt $out/bin $out/share
    cp -r usr/lib/claude-desktop $out/opt/claude-desktop
    # Needs a setuid root helper, impossible in the store; user namespaces
    # (on by default in NixOS) cover the sandbox instead.
    rm $out/opt/claude-desktop/chrome-sandbox
    cp -r usr/share/icons $out/share/icons
    install -Dm644 usr/share/applications/com.anthropic.Claude.desktop \
      $out/share/applications/com.anthropic.Claude.desktop
    substituteInPlace $out/share/applications/com.anthropic.Claude.desktop \
      --replace-fail "Exec=claude-desktop" "Exec=$out/bin/claude-desktop"

    makeWrapper $out/opt/claude-desktop/claude-desktop $out/bin/claude-desktop \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeLibs} \
      --prefix PATH : ${lib.makeBinPath [ xdg-utils ]}

    runHook postInstall
  '';

  meta = {
    description = "Claude Desktop, Anthropic's official Linux app";
    homepage = "https://claude.com/download";
    license = lib.licenses.unfree;
    mainProgram = "claude-desktop";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
