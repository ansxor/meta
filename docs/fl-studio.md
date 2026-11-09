# FL Studio

FL Studio runs under stock Wine 11.21 in one writable prefix, with the PipeASIO
driver for low-latency audio. No ready-made Nix package or flake for this turned
up in a search; the setup follows
[FL Studio 2026 on Linux with Windows plugins and iLok Cloud](https://pr1v8.ca/posts/fl-studio-wine-plugins-ilok/)
and turns its manual steps into local packages.

| Piece | What it is |
|---|---|
| `nixpkgs-wine` (flake input) | A second nixpkgs, pinned to a commit whose Wine 11.21 is in the binary cache, so it is only downloaded, never compiled. |
| `pkgs/pipeasio` | [PipeASIO](https://github.com/M0n7y5/pipeasio) 1.7.0, an ASIO driver that talks to PipeWire directly, built against that Wine (a small C build). |
| `pkgs/fl-studio` | The `fl-studio` command: prefix setup, installer, launcher and menu entry. |

Wired up in `home/answer/packages/media.nix`.

**Why a second nixpkgs.** Wine 11.19, which the main `nixpkgs` lock has, cannot
start FL Studio 2026: it stops at "The validity of the program could not be
verified" (Wine bug 60273). The fix is in Wine 11.21. Overriding Wine's version
in the main nixpkgs would compile Wine from source, so the input points at a
commit that already has a cached 11.21 build instead. Drop the input and use
`pkgs.wineWow64Packages.unstableFull` once the main `nixpkgs` has Wine 11.21 or
newer. Do not `nix flake update nixpkgs-wine` to an arbitrary commit: if that
commit's Wine is not cached yet, Nix would compile it.

## First run

FL Studio is proprietary, so the installer is not in the package. Download the
Windows installer from Image-Line, then:

```sh
fl-studio install ~/Downloads/flstudio_win64_*.exe
```

That creates the prefix in `~/.local/share/wineprefixes/flstudio` (override with
`FL_STUDIO_PREFIX`), installs `corefonts` and the Microsoft C++ runtime (it needs
network), registers PipeASIO, applies the registry settings, and runs Image-Line's
installer. Log in to your Image-Line account from inside FL.

Then start it from the menu or with `fl-studio`. In FL, choose **PipeASIO**
under Options → Audio and turn off "Mix in buffer switch" (it causes crackling).
The buffer size is in `~/.config/pipeasio/config.ini`.

## Commands

```
fl-studio                    start FL Studio
fl-studio FILE.flp           open a project
fl-studio flstudio://...     hand a protocol link (the Image-Line login) to FL
fl-studio install EXE        set up the prefix and run Image-Line's installer
fl-studio setup [--dpi N]    reapply the prefix settings; safe to repeat
fl-studio --app EXE          run another program of the prefix (Unix path)
fl-studio --open FILE        run an .exe/.bat/.cmd in the prefix and wait
```

Closing FL stops the whole prefix, services included. Logs go to
`~/.cache/fl-studio/` when started from the menu.

Wine ignores the desktop scale factor: if the UI is too small, run
`fl-studio setup --dpi 120` (96 is 100 %, 120 is 125 %, 144 is 150 %).

## Plugins

Windows plugins load inside FL's own Wine process, exactly as on Windows, so
yabridge is not needed. Install them with the same Wine:

```sh
fl-studio --open ~/Downloads/plugin-installer.exe
```

Silent switches save clicks: Inno Setup `/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-`,
NSIS `/S`, MSI `msiexec /i package.msi /qn`. Installers use three different VST2
folders (`Common Files\VST2`, `Program Files\Vstplugins`,
`Program Files\Steinberg\VSTPlugins`); add all three to FL's plugin search paths or
stick to VST3. iLok Cloud works in principle (run the iLok License Support
installer with `--open`); USB dongles do not, since Wine cannot load their kernel
driver.

**Known limit of stock Wine.** The linked guide patches Wine for plugin windows:
JUCE 7 editors (for example Trackspacer, Wider, ShaperBox 3, Kickstart 2) can
open frozen or black, JUCE 8 editors (soothe3) can stay blank, and Serum can
freeze FL on load. Those fixes are not in Wine 11.21, and they require compiling
a patched Wine, which this config deliberately does not do. FL's own instruments
and effects are not affected.

## Maintenance

- **Prefix upgrades.** After a Wine change, Wine updates the prefix on the next
  start and can put its own `msvcp140.dll` back; run `fl-studio setup` to restore
  Microsoft's. Raise `stamp_version` in `pkgs/fl-studio/fl-studio.sh` to force the
  fonts and runtime to be reinstalled.
