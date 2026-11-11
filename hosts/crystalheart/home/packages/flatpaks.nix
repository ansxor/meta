{ inputs, lib, ... }:

# Declarative Flatpaks (user installation) via nix-flatpak. Every switch
# installs anything missing; an app removed from this list is uninstalled.
# Apps installed by hand are left alone (uninstallUnmanaged = false).
{
  imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];

  services.flatpak = {
    enable = true;

    remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
      # Vintage Story publishes no .flatpakrepo file; the key is the one the
      # Arch install had trusted (fingerprint E24A5257F86D9C9133DA87B10DF9B1FA9B3C4587).
      {
        name = "vintagestory";
        location = "https://flatpak.vintagestory.at/repo/";
        gpg-import = "${../../../../dotfiles/flatpak/vintagestory.gpg}";
      }
    ];

    # Weekly `flatpak update`; switches only install, so they stay fast.
    update.auto = {
      enable = true;
      onCalendar = "weekly";
    };

    # Captured from Arch. Apps that came from
    # one-off bundles or .flatpakref files (Hytale launcher, Hangar, Amulet,
    # WiiU Downloader, Zelda 64 Recompiled) have no repository to pin, so
    # they stay manual installs.
    packages = [
      "ca._0ldsk00l.Nestopia"
      "ca.parallel_launcher.ParallelLauncher"
      "com.adobe.Flash-Player-Projector"
      "com.bitwarden.desktop"
      "com.calibre_ebook.calibre"
      "com.cherry_ai.CherryStudio"
      "com.github.IsmaelMartinez.teams_for_linux"
      "com.github.Matoking.protontricks"
      "com.github.Rosalie241.RMG"
      "com.github.cubitect.cubiomes-viewer"
      "com.github.finefindus.eyedropper"
      "com.github.tchx84.Flatseal"
      "com.github.tenderowl.frog"
      "com.github.xournalpp.xournalpp"
      "com.lunarclient.LunarClient"
      "com.mattjakeman.ExtensionManager"
      "com.microsoft.Edge"
      "com.modrinth.ModrinthApp"
      "com.slack.Slack"
      "com.steamgriddb.SGDBoop"
      "com.teamspeak.TeamSpeak3"
      "com.tutanota.Tutanota"
      "com.usebottles.bottles"
      "com.yktoo.ymuse"
      "dev.bambosh.UnofficialHomestuckCollection"
      "dev.goats.xivlauncher"
      "dev.k8slens.OpenLens"
      "io.bassi.Amberol"
      "io.github.Foldex.AdwSteamGtk"
      "io.github.alainm23.planify"
      "io.github.brunofin.Cohesion"
      "io.github.gopher64.gopher64"
      "io.github.kolunmi.Bazaar"
      "io.github.mrvladus.List"
      "io.github.wartybix.Constrict"
      "io.gitlab.adhami3310.Converter"
      "io.missioncenter.MissionCenter"
      "io.typora.Typora"
      "it.mijorus.gearlever"
      "it.mijorus.smile"
      "net.ankiweb.Anki"
      "net.blockbench.Blockbench"
      "net.davidotek.pupgui2"
      "net.pcsx2.PCSX2"
      "net.puddletag.puddletag"
      "net.sapples.LiveCaptions"
      "org.DolphinEmu.dolphin-emu"
      "org.ardour.Ardour"
      "org.audacityteam.Audacity"
      "org.azahar_emu.Azahar"
      "org.desmume.DeSmuME"
      "org.filezillaproject.Filezilla"
      "org.getmonero.Monero"
      "org.gimp.GIMP"
      "org.gnome.Evolution"
      "org.gnome.Todo"
      "org.gnome.gitlab.YaLTeR.VideoTrimmer"
      "org.inkscape.Inkscape"
      "org.kde.kleopatra"
      "org.kde.krita"
      "org.libreoffice.LibreOffice"
      "org.localsend.localsend_app"
      "org.love2d.love2d"
      "org.mamedev.MAME"
      "org.mozilla.thunderbird_esr"
      "org.mypaint.MyPaint"
      "org.nicotine_plus.Nicotine"
      # Flathub has stable and lts branches; flatpak won't pick one
      # non-interactively and the whole install run fails.
      "org.qgis.qgis//stable"
      "org.signal.Signal"
      "org.sqlitebrowser.sqlitebrowser"
      "org.telegram.desktop"
      "org.vinegarhq.Sober"
      "org.zotero.Zotero"
      "sh.ppy.osu"
      "us.zoom.Zoom"
      {
        appId = "at.vintagestory.VintageStory";
        origin = "vintagestory";
      }
    ];
  };

  # Upstream makes the installer a oneshot, so both Home Manager's sd-switch
  # and the module's own activation step wait for every download to finish;
  # a first install overruns home-manager-answer.service's start timeout and
  # fails the switch. "exec" returns once the installer has started.
  systemd.user.services.flatpak-managed-install.Service.Type = lib.mkForce "exec";
}
