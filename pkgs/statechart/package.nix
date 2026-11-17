# TLA+ statechart checker for the `statechart` agent skill
# (dotfiles/agents/skills/statechart). Runs on Node's built-in TypeScript
# support; TLC and Java come from Nix, so no network or mise at run time.
{
  lib,
  stdenvNoCC,
  makeWrapper,
  nodejs,
  tlaplus,
  jre_headless,
}:

stdenvNoCC.mkDerivation {
  pname = "statechart";
  version = "0-unstable";
  src = lib.fileset.toSource {
    root = ./src;
    fileset = ./src;
  };

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/statechart
    cp -r . $out/lib/statechart
    makeWrapper ${lib.getExe nodejs} $out/bin/statechart \
      --add-flags "--disable-warning=ExperimentalWarning $out/lib/statechart/statechart.ts" \
      --set-default TLA2TOOLS ${tlaplus}/share/java/tla2tools.jar \
      --set-default JAVA ${lib.getExe jre_headless}
    runHook postInstall
  '';

  meta = {
    description = "Check a TLA+ model with TLC and draw it as a Mermaid statechart";
    mainProgram = "statechart";
    platforms = lib.platforms.linux;
  };
}
