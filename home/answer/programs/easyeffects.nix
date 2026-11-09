{ pkgs, lib, ... }:

let
  json = pkgs.formats.json { };
  presetDir = ../../../dotfiles/easyeffects/presets;

  presets = {
    Edifier = (lib.importJSON "${presetDir}/Edifier.json").output;
    KPH40 = (lib.importJSON "${presetDir}/KPH40.json").output;
    KSC75 = (lib.importJSON "${presetDir}/KSC75.json").output;
    "KT 770" = (lib.importJSON "${presetDir}/KT 770.json").output;
    "Timeless 7hz" = (lib.importJSON "${presetDir}/Timeless 7hz.json").output;
    "soundcore Q30 ANC" = (lib.importJSON "${presetDir}/soundcore Q30 ANC.json").output;
  };

  # The device:route names are the autoload keys EasyEffects derives from
  # PipeWire. Keep them exactly as the device names appear in pw-dump.
  autoload = {
    "alsa_output.pci-0000_2d_00.1.hdmi-stereo:hdmi-output-0" = {
      device = "alsa_output.pci-0000_2d_00.1.hdmi-stereo";
      device-description = "Navi 31 HDMI/DP Audio Digital Stereo (HDMI)";
      device-profile = "hdmi-output-0";
      preset-name = "Edifier";
    };
    "alsa_output.usb-Focusrite_Scarlett_Solo_USB_Y7CA0AT19D1CEA-00.Direct__Direct__sink:[Out] Direct" =
      {
        device = "alsa_output.usb-Focusrite_Scarlett_Solo_USB_Y7CA0AT19D1CEA-00.Direct__Direct__sink";
        device-description = "Scarlett Solo (3rd Gen.) Direct Scarlett Solo USB";
        device-profile = "[Out] Direct";
        preset-name = "KPH40";
      };
  };
in
{
  services.easyeffects = {
    enable = true;
    preset.output = "KPH40";
    # Only the output chain is used. EasyEffects' input side must stay off
    # HushMic: by default it follows the default source (hushmic_source) and
    # grabs every recording stream, including HushMic's own capture, which
    # made a feedback loop (fifine never reached HushMic, so apps got silence).
    settings.StreamInputs = {
      processAllInputs = false;
      blocklist = "hushmic_input";
      useDefaultInputDevice = false;
      inputDevice = "alsa_input.usb-3142_fifine_Microphone_000000000000-00.mono-fallback";
    };
    extraPresets = lib.mapAttrs (_: output: { inherit output; }) presets;
  };

  xdg.dataFile = lib.mapAttrs' (
    name: profile:
    lib.nameValuePair "easyeffects/autoload/output/${name}.json" {
      source = json.generate "easyeffects-autoload.json" profile;
    }
  ) autoload;
}
