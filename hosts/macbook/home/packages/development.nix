{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Editors
    neovim
    helix

    # Toolchains and build tools (captured from Homebrew leaves)
    gcc
    cmake
    ninja
    pkg-config
    autoconf
    autoconf-archive
    automake
    libtool
    gettext
    ccache
    gperf
    expat
    libxml2
    glslang
    spirv-cross
    spirv-headers
    spirv-tools
    go
    sbcl
    jdk17
    nodejs
    pnpm
    bun
    deno
    uv
    mise

    # DevOps / VCS / code quality
    gh
    google-cloud-sdk
    just
    jujutsu
    git-filter-repo
    git-crypt
    go-task
    railway
    ruff
    prettier
    pyright
    basedpyright
    typescript-language-server
    beads

    # Local AI (Apple Silicon Metal)
    llama-cpp
    ollama

    # Android / reverse engineering / virtualisation
    apktool
    jadx
    scrcpy
    ghidra
    qemu
  ];
}
