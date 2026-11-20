# LearnHarness (https://learnharness.ai), upstream AppImage release from
# https://github.com/amosblomqvist/learnharness. Not in nixpkgs.
{
  appimageTools,
  fetchurl,
}:

let
  pname = "learnharness";
  version = "0.6.1";

  src = fetchurl {
    url = "https://github.com/amosblomqvist/learnharness/releases/download/v${version}/LearnHarness-${version}-x86_64.AppImage";
    hash = "sha256-uKAz63QhZ3iT2W5JiLMBU/3+T8bw3EVveUcWG7oEG5g=";
  };

  contents = appimageTools.extract {
    inherit pname version src;
    postExtract = ''
      patch --directory="$out" --strip=1 --fuzz=0 < ${./gpt-6.2-sol.patch}
      patch --directory="$out" --strip=1 --fuzz=0 < ${./pi-codex-prompt-cache.patch}
    '';
  };
in
appimageTools.wrapAppImage {
  inherit pname version contents;
  passthru = { inherit src; };

  extraInstallCommands = ''
    install -Dm444 ${contents}/*.desktop -t $out/share/applications
    substituteInPlace $out/share/applications/*.desktop \
      --replace-quiet 'Exec=AppRun' 'Exec=${pname}'
    cp -r ${contents}/usr/share/icons $out/share/ || true
  '';
}
