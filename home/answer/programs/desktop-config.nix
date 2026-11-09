{
  lib,
  pkgs,
  ...
}:

let
  gv = lib.hm.gvariant;

  wallpaper = ../../../dotfiles/wallpapers/2026-07-03-15-06-02-a.png;
in
{
  # darkman owns org.gnome.desktop.interface color-scheme, so dconf.settings
  # below must not pin it. These replace the Arch mode scripts (#!/bin/bash +
  # nwg-look).
  services.darkman =
    let
      dconf = lib.getExe' pkgs.dconf "dconf";
    in
    {
      enable = true;
      settings = {
        lat = 45.4;
        lng = -75.7;
        dbusserver = true;
      };
      darkModeScripts.gtk-color-scheme = "${dconf} write /org/gnome/desktop/interface/color-scheme \"'prefer-dark'\"";
      lightModeScripts.gtk-color-scheme = "${dconf} write /org/gnome/desktop/interface/color-scheme \"'prefer-light'\"";
    };

  # X11/XWayland clients without XSETTINGS fall back to the "default" cursor
  # theme. Not home.pointerCursor: it exports XCURSOR_SIZE, which X11 clients
  # read as physical pixels, so with 2x scaling their cursor is half size.
  # Without it they take the scaled size from GNOME.
  home.file.".icons/default/index.theme".text = ''
    [Icon Theme]
    Name=Default
    Comment=Default Cursor Theme
    Inherits=Adwaita
  '';

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      accent-color = "pink";
      clock-format = "12h";
      clock-show-date = false;
      clock-show-seconds = false;
      clock-show-weekday = true;
      cursor-blink = true;
      cursor-blink-time = 1000;
      cursor-size = 24;
      cursor-theme = "Adwaita";
      document-font-name = "Noto Sans 10";
      enable-animations = true;
      font-antialiasing = "grayscale";
      font-hinting = "medium";
      font-name = "Sans 10";
      font-rgba-order = "rgb";
      gtk-theme = "Adwaita";
      icon-theme = "Adwaita";
      monospace-font-name = "Hack 10";
      scaling-factor = gv.mkUint32 2;
      text-scaling-factor = 1.0;
      toolkit-accessibility = true;
    };

    "org/gnome/desktop/wm/preferences" = {
      action-middle-click-titlebar = "lower";
      audible-bell = false;
      button-layout = "icon:minimize,maximize,close";
      focus-mode = "click";
      num-workspaces = 4;
      theme = "Adwaita";
      titlebar-font = "Sans Bold 10";
    };

    "org/gnome/desktop/input-sources" = {
      show-all-sources = false;
      sources = gv.mkArray "(ss)" [
        (gv.mkTuple [
          "xkb"
          "us"
        ])
        (gv.mkTuple [
          "xkb"
          "ca"
        ])
      ];
      xkb-options = [ ];
    };

    "org/gnome/desktop/peripherals/mouse" = {
      accel-profile = "flat";
      double-click = 400;
      drag-threshold = 8;
      left-handed = false;
      natural-scroll = false;
      speed = 0.0;
    };

    "org/gnome/desktop/peripherals/touchpad" = {
      two-finger-scrolling-enabled = true;
    };

    "org/gnome/desktop/session" = {
      idle-delay = gv.mkUint32 0;
    };

    "org/gnome/desktop/background" = {
      color-shading-type = "solid";
      picture-options = "zoom";
      picture-uri = "file://${wallpaper}";
      picture-uri-dark = "file://${wallpaper}";
      primary-color = "#000000000000";
      secondary-color = "#000000000000";
    };

    "org/gnome/desktop/calendar" = {
      show-weekdate = true;
    };

    "org/gnome/desktop/notifications" = {
      show-banners = true;
    };

    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "icon-view";
    };

    "org/gnome/mutter" = {
      edge-tiling = true;
    };

    "org/gnome/shell/extensions/just-perfection" = {
      accent-color-icon = false;
      accessibility-menu = false;
      activities-button = true;
      animation = 4;
      clock-menu = true;
      clock-menu-position = 1;
      clock-menu-position-offset = 13;
      controls-manager-spacing-size = 0;
      dash-icon-size = 0;
      invert-calendar-column-items = false;
      keyboard-layout = false;
      panel = true;
      panel-button-padding-size = 3;
      panel-icon-size = 0;
      panel-in-overview = true;
      panel-indicator-padding-size = 0;
      panel-size = 26;
      power-icon = true;
      quick-settings = true;
      quick-settings-airplane-mode = true;
      quick-settings-backlight = true;
      quick-settings-dark-mode = true;
      ripple-box = true;
      search = true;
      show-apps-button = true;
      startup-status = 1;
      theme = true;
      top-panel-position = 1;
      window-demands-attention-focus = false;
      window-menu-take-screenshot-button = true;
      window-picker-icon = true;
      workspace = true;
      workspace-switcher-size = 0;
      workspace-wrap-around = true;
      workspaces-in-app-grid = true;
      world-clock = true;
    };

    "org/gnome/shell" = {
      enabled-extensions = [
        "osd-volume-number@deminder"
        "caffeine@patapon.info"
        "appindicatorsupport@rgcjonas.gmail.com"
        "gsconnect@andyholmes.github.io"
        "quick-settings-tweaks@qwreey"
        "just-perfection-desktop@just-perfection"
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "screenshot-window-sizer@gnome-shell-extensions.gcampax.github.com"
        "tailscale-gnome-qs@tailscale-qs.github.io"
        "mprisLabel@moon-0xff.github.com"
        "eepresetselector@ulville.github.io"
        "focused-window-dbus@flexagoon.com"
        "system-monitor-next@paradoxxx.zero.gmail.com"
        "hermes-hud-above@hermes-agent.dev"
        "winrects@cua"
        "smile-extension@mijorus.it"
      ];
      favorite-apps = [
        "zen.desktop"
        "org.gnome.Nautilus.desktop"
        "com.mitchellh.ghostty.desktop"
        "steam.desktop"
      ];
    };
  };
}
