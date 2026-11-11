{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Editors
    neovim
    helix
    kakoune
    emacs-pgtk
    vscode
    super
    sublime4
    zed-editor
    dafny
    alloy6
    jetbrains-toolbox

    # Toolchains
    gcc
    cmake
    ninja
    meson
    pkg-config
    autoconf
    automake
    libtool
    bison
    flex
    patch
    gettext
    texinfo
    gdb
    valgrind
    ctags
    global
    glib
    cli11
    spirv-cross
    ghc
    cabal-install
    haxe
    jdk
    openjfx
    dotnet-sdk_8
    nodejs
    pnpm
    bun
    deno
    uv
    poetry
    pipx
    pyenv
    asdf-vm
    mise

    # Python environment carried over from the Arch install
    (python3.withPackages (
      ps: with ps; [
        numpy
        openpyxl
        huggingface-hub
        websocket-client
        playwright
        pyqt6
        pyqt6-webengine
        pyqt6-sip
        mysqlclient
        faster-whisper
        openai-whisper
        torch
      ]
    ))

    # DevOps / cloud / code quality
    terraform
    helm
    kubectl
    k9s
    kind
    kompose
    vultr-cli
    awscli2
    stripe-cli
    github-cli
    gh
    act
    ngrok
    upterm
    mkcert
    just
    jujutsu
    fossil
    git-filter-repo
    git-crypt
    ruff
    prettier
    pyright
    basedpyright
    typescript-language-server
    bandit
    hugo
    # `bd` issue tracker (Linuxbrew on Arch); bundles its own Dolt.
    beads

    # Databases
    mysql-workbench
    letos
    valkey
    postgresql
    mariadb.client

    # Local AI / ROCm
    llama-cpp-vulkan
    ollama
    rocmPackages.clr
    rocmPackages.rocm-smi
    rocmPackages.rocminfo

    # Android / security
    android-tools
    scrcpy
    radare2
    ghidra

    # Virtualisation clients
    distrobox
    winboat
    looking-glass-client
    virt-manager
  ];
}
