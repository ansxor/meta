{
  description = "CrystalHeart — NixOS configuration migrated from Arch Linux";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Time Timer (libadwaita) study timer (home/answer/packages/desktop.nix).
    time-timer = {
      url = "git+https://tangled.org/ansxor.ca/time-timer-adwaita";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Wine 11.21 for FL Studio (pkgs/fl-studio, home/answer/packages/media.nix).
    # FL Studio needs the crypt32 signature fix that is in Wine 11.21 but not in
    # the 11.19 our main nixpkgs lock has, and a Wine override would compile
    # Wine from source. Pinned to a nixos-unstable commit whose Wine is in the
    # binary cache (checked with `nix build --dry-run`: fetch only). Pinning the
    # rev in the URL keeps `nix flake update` from moving it to a commit whose
    # Wine is not cached yet. Drop this input when `nixpkgs` has Wine >= 11.21.
    nixpkgs-wine.url = "github:NixOS/nixpkgs/f4a03c008967841f2a0b3cb7c436fc6fc31671f6";

    # BizHawk's own Nix expression (pkgs/bizhawk); not a flake.
    bizhawk = {
      url = "github:TASEmulators/BizHawk";
      flake = false;
    };

    # WiVRn fork (modules/nixos/gaming.nix); its flake overrides nixpkgs'
    # wivrn with this checkout's source.
    wivrn = {
      url = "git+https://git.shsbs.xyz/ansxor/wivrn";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Logitech TrueForce wheel driver (G923 and RS50/G PRO; the G920 does not
    # need it). Pinned to the tag the Arch package used (0.42.6). Its NixOS
    # packages are used in modules/nixos/gaming.nix.
    logitech-trueforce = {
      url = "github:mescon/logitech-trueforce-linux-driver/v0.42.6";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative Flatpaks (home/answer/packages/flatpaks.nix). "latest" is
    # upstream's release tag; flake.lock pins the commit.
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    # Hex local voice dictation + Home Manager module
    # (home/answer/programs/hex.nix). Follows our nixpkgs so it uses the same
    # glibc as the graphics drivers, as its Nix guide requires.
    hex = {
      url = "github:anomalyco/hex";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # OpenClaw gateway + Home Manager module (home/answer/programs/openclaw.nix).
    # Keeps its own nixpkgs: its Node 24.22.1 fallback binary segfaults when
    # autoPatchelf'd with our newer toolchain (glibc/gcc 16, patchelf 0.19.2).
    nix-openclaw = {
      url = "github:openclaw/nix-openclaw";
      inputs.home-manager.follows = "home-manager";
    };

    # Save sync, game locks and handoffs (modules/nixos/game-handoff.nix,
    # home/answer/programs/game-handoff.nix). Local repo: commit there, then
    # `nix flake update game-handoff`.
    game-handoff = {
      url = "git+file:///home/answer/Workspace/game-handoff";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nixos-hardware,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # nix-openclaw's overlay on its own pinned nixpkgs (as in its
      # agent-first template), not on ours; see the input comment.
      openclawPkgs = import inputs.nix-openclaw.inputs.nixpkgs {
        inherit system;
        overlays = [ inputs.nix-openclaw.overlays.default ];
      };
    in
    {
      nixosConfigurations.crystalheart = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/crystalheart
          home-manager.nixosModules.home-manager
          {
            # The pkgs.openclaw* attributes the nix-openclaw Home Manager module
            # reads from the system pkgs (useGlobalPkgs).
            nixpkgs.overlays = [
              (_: _: {
                inherit (openclawPkgs) openclaw openclawPackages openclawRuntimePlugins;
              })
            ];

            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.backupFileExtension = "hm-backup";
            home-manager.users.answer = import ./home/answer;
          }
        ];
      };

      # `nix develop .#wivrn-apk`; see scripts/build-wivrn-apk.sh.
      devShells.${system}.wivrn-apk = import ./wivrn-apk.nix { inherit inputs system; };

      # `nix fmt` formats the whole tree with the pinned nixfmt.
      formatter.${system} = pkgs.nixfmt-tree;

      # `nix flake check` also evaluates nixosConfigurations.crystalheart.
      checks.${system} = import ./checks.nix { inherit self pkgs; };
    };
}
