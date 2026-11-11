{ inputs, pkgs, ... }:

let
  # FL Studio runs under stock Wine 11.21 from a second, pinned nixpkgs (a
  # cached binary, never compiled here), with the PipeASIO driver built
  # against that same Wine. See docs/fl-studio.md.
  flWine =
    inputs.nixpkgs-wine.legacyPackages.${pkgs.stdenv.hostPlatform.system}.wineWow64Packages.unstableFull;
  pipeasio = pkgs.callPackage ../../../../pkgs/pipeasio/package.nix { wine = flWine; };
in
{
  home.packages = [
    # Not in nixpkgs; local package of the upstream release (pkgs/hushmic).
    (pkgs.callPackage ../../../../pkgs/hushmic/package.nix { })

    # `fl-studio install <Image-Line installer>` sets up the prefix.
    (pkgs.callPackage ../../../../pkgs/fl-studio/package.nix {
      wine = flWine;
      inherit pipeasio;
    })
  ]
  ++ (with pkgs; [
    vlc
    mpv
    celluloid
    obs-studio
    obs-studio-plugins.input-overlay
    blender
    calibre
    pinta
    aseprite
    gst_all_1.gst-plugins-bad
    yt-dlp
    ffmpeg
    spotify
    spicetify-cli
  ]);
}
