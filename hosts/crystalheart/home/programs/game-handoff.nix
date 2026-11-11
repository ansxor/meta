{
  inputs,
  lib,
  pkgs,
  ...
}:

# Game Handoff: save sync, per-game locks and handoffs. melonDS comes from this
# repo's patched build (nix/game-handoff flake) and is configured as the
# melonds emulator for the nds platform.
let
  # The Steam Controller (28de:1304 puck) has no SDL driver here; Steam's
  # gamepad mode exposes it as a virtual "Microsoft X-Box 360 pad", which
  # SDL hides from programs Steam didn't launch. Unhide it for apps run
  # directly from the desktop.
  melonds =
    (inputs.game-handoff.packages.${pkgs.stdenv.hostPlatform.system}.melonds-handoff).overrideAttrs
      (old: {
        qtWrapperArgs = old.qtWrapperArgs ++ [
          "--set-default SDL_GAMECONTROLLER_ALLOW_STEAM_VIRTUAL_GAMEPAD 1"
        ];
      });
in
{
  imports = [ inputs.game-handoff.homeManagerModules.default ];

  programs.game-handoff = {
    enable = true;
    melondsPackage = melonds;

    settings = {
      server = "http://127.0.0.1:7480";
      device_name = "CrystalHeart";

      platforms.nds = {
        rom_dir = "~/Games/DS";
        extensions = [
          "nds"
          "dsi"
          "srl"
        ];
        emulator = "melonds";
      };

      emulators.melonds = {
        command = [
          (lib.getExe melonds)
          "{rom}"
        ];
        resume_args = [
          "--handoff-state"
          "{state}"
        ];
        integration = "native";
      };
    };
  };
}
