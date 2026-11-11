{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ffmpeg
    mpv
    poppler
    yt-dlp
  ];
}
