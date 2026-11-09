#!/usr/bin/env bash
# FL Studio under Wine 11.21, in one writable prefix outside the Nix store.
#
#   fl-studio                    start FL Studio
#   fl-studio FILE.flp           open a project
#   fl-studio flstudio://...     hand an Image-Line login/protocol link to FL
#   fl-studio install EXE        set up the prefix, run Image-Line's installer
#   fl-studio setup [--dpi N]    (re)apply the prefix settings; safe to repeat
#   fl-studio --app EXE          run another program of the prefix (Unix path)
#   fl-studio --open FILE        run an .exe/.bat/.cmd in the prefix and wait
#
# FL_STUDIO_PREFIX overrides the prefix location.

wine=@wine@/bin/wine
wineserver=@wine@/bin/wineserver
pipeasio=@pipeasio@

export WINEPREFIX="${FL_STUDIO_PREFIX:-${XDG_DATA_HOME:-$HOME/.local/share}/wineprefixes/flstudio}"
export WINEARCH=win64
export WINEDEBUG="${WINEDEBUG:-fixme-all}" # keep err: lines and crash reports
# Wine finds a builtin driver's Unix half only in its own library dir or here.
export WINEDLLPATH="$pipeasio/lib/wine${WINEDLLPATH:+:$WINEDLLPATH}"
# winetricks picks the Wine to drive from these.
export WINE="$wine" WINESERVER="$wineserver"

say() { printf 'fl-studio: %s\n' "$*" >&2; }
die() {
  say "$*"
  exit 1
}

# Newest installed FL Studio, as a Unix path; empty when none.
find_fl() {
  local dir="$WINEPREFIX/drive_c/Program Files/Image-Line" found=
  [ -d "$dir" ] || return 0
  found=$(printf '%s\n' "$dir"/FL\ Studio*/FL64.exe | sort -V | tail -n 1)
  [ -f "$found" ] && printf '%s' "$found"
  return 0
}

# Runs after FL's own installer and on every `setup`; every step is idempotent.
wine_reg() { "$wine" reg add "$@" /f >/dev/null; }

apply_registry() {
  local key
  # Wine only offers the right-hand side of Windows' ClearType RGB smoothing.
  wine_reg 'HKCU\Control Panel\Desktop' /v FontSmoothing /t REG_SZ /d 2
  wine_reg 'HKCU\Control Panel\Desktop' /v FontSmoothingType /t REG_DWORD /d 2
  wine_reg 'HKCU\Control Panel\Desktop' /v FontSmoothingGradientOrientation /t REG_DWORD /d 1
  wine_reg 'HKCU\Control Panel\Desktop' /v FontSmoothingOrientation /t REG_DWORD /d 1

  # Menu entries come from Nix, not from whatever the installers drop in
  # ~/.local/share/applications/wine.
  wine_reg 'HKCU\Software\Wine\DllOverrides' /v winemenubuilder.exe /d ''

  # WebView2 (the FL Cloud and browser panes) crash-loops its GPU process when
  # Windows reports 8.1+, because Wine's DirectComposition device is a stub on
  # the paths Chromium takes. Telling only the runtime it is on Windows 8 fixes
  # it; FL itself still sees Windows 10.
  wine_reg 'HKCU\Software\Wine\AppDefaults\msedgewebview2.exe' /v Version /t REG_SZ /d win8

  # The WebView2 installer leaves Edge's update services running, which keeps
  # the prefix alive after FL exits. Disable them, but only when they exist: a
  # bare service key would make Wine's services.exe log errors.
  for key in edgeupdate edgeupdatem; do
    if "$wine" reg query "HKLM\\System\\CurrentControlSet\\Services\\$key" >/dev/null 2>&1; then
      wine_reg "HKLM\\System\\CurrentControlSet\\Services\\$key" /v Start /t REG_DWORD /d 4
    fi
  done
  # Do not let the runtime update itself past the version that was tested.
  wine_reg 'HKLM\Software\Policies\Microsoft\EdgeUpdate' /v UpdateDefault /t REG_DWORD /d 0

  if [ -n "${dpi:-}" ]; then
    # Wine ignores the desktop scale factor: 96 is 100 %, 120 is 125 %, 144 is 150 %.
    wine_reg 'HKCU\Control Panel\Desktop' /v LogPixels /t REG_DWORD /d "$dpi"
  fi
}

# winetricks' vcrun2022 leaves Wine's own msvcp140.dll in place, and some
# plugins (PACE-protected ones in particular) need functions it lacks. The
# redistributable's cabinets name the files msvcp140.dll_amd64 / _x86, so
# unpack them and copy them over by hand.
install_vc_runtime() {
  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/winetricks/vcrun2022"
  local spec arch dir suffix work file target

  winetricks -q vcrun2022 || say "winetricks vcrun2022 failed; trying the cached download anyway"
  work=$(mktemp -d)
  for spec in x64:system32:amd64 x86:syswow64:x86; do
    IFS=: read -r arch dir suffix <<<"$spec"
    [ -f "$cache/vc_redist.$arch.exe" ] || {
      say "no $cache/vc_redist.$arch.exe; skipping the $arch runtime"
      continue
    }
    mkdir -p "$work/$arch/out"
    (
      cd "$work/$arch" || exit 1
      cabextract -q -L "$cache/vc_redist.$arch.exe"
      for cab in a*; do
        [ -f "$cab" ] && cabextract -q -L -d out "$cab" 2>/dev/null
      done
      true
    )
    for file in "$work/$arch"/out/*_"$suffix"; do
      [ -f "$file" ] || continue
      target=$(basename "$file" "_$suffix")
      cp -f "$file" "$WINEPREFIX/drive_c/windows/$dir/$target"
    done
  done
  rm -rf "$work"
}

stamp_version=2

setup() {
  if [ ! -f "$WINEPREFIX/system.reg" ]; then
    say "creating the Wine prefix in $WINEPREFIX"
    mkdir -p "$WINEPREFIX"
    "$wine" wineboot -i
    "$wineserver" -w
  fi

  if [ "$(cat "$WINEPREFIX/.fl-studio-nix" 2>/dev/null)" != "$stamp_version" ]; then
    say "installing fonts and the C++ runtime (needs network)"
    winetricks -q corefonts || say "corefonts failed; run 'fl-studio setup' again later"
    install_vc_runtime
    printf '%s' "$stamp_version" >"$WINEPREFIX/.fl-studio-nix"
  fi

  # Registers the ASIO driver for this prefix; reruns just refresh it.
  PIPEASIO_PREFIX="$pipeasio" WINE="$wine" "$pipeasio/bin/pipeasio-register" ||
    say "PipeASIO registration failed; FL's ASIO driver list will be empty"

  apply_registry
}

# Pull FL's icon out of FL64.exe for the menu entry, once.
install_icon() {
  local fl=$1 work ico png size
  local icons="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor"
  [ -f "$icons/256x256/apps/fl-studio.png" ] && return 0
  work=$(mktemp -d)
  mkdir -p "$work/ico" "$work/png"
  wrestool -x -t 14 -o "$work/ico" "$fl" 2>/dev/null
  for ico in "$work"/ico/*.ico; do
    [ -f "$ico" ] && icotool -x -o "$work/png" "$ico" 2>/dev/null
  done
  # icotool names its output <icon>_<index>_<W>x<H>x<depth>.png.
  for png in "$work"/png/*.png; do
    [[ $png =~ _([0-9]+x[0-9]+)x[0-9]+\.png$ ]] || continue
    size=${BASH_REMATCH[1]}
    mkdir -p "$icons/$size/apps"
    cp -f "$png" "$icons/$size/apps/fl-studio.png"
  done
  rm -rf "$work"
}

# Desktop launchers pass stdout/stderr as a journal socket, which Wine hands on
# as a handle Electron apps cannot open. Outside a terminal, log to a file.
redirect_logs_unless_tty() {
  local name=$1 logdir="${XDG_CACHE_HOME:-$HOME/.cache}/fl-studio"
  [ -t 2 ] && return 0
  mkdir -p "$logdir"
  exec >"$logdir/$name.log" 2>&1 </dev/null
}

# FL closing ends every process in the prefix. A side program closing ends it
# only when neither FL nor another program started by this script still runs.
stop_prefix_unless_busy() {
  local mode=$1 others
  if [ "$mode" = fl ]; then
    pgrep -x FL64.exe >/dev/null || "$wineserver" -k
  else
    others=$(pgrep -f 'bin/\.?fl-studio' | grep -vx "$$")
    pgrep -x FL64.exe >/dev/null || [ -n "$others" ] || "$wineserver" -k
  fi
}

dpi=

cmd=${1:-}
case "$cmd" in
setup)
  shift
  if [ "${1:-}" = --dpi ]; then dpi=${2:?--dpi needs a number}; fi
  setup
  ;;

install)
  installer=${2:?usage: fl-studio install /path/to/flstudio_win64_*.exe}
  [ -f "$installer" ] || die "no such file: $installer"
  setup
  say "starting the installer; finish its window, then FL Studio is ready"
  (cd "$(dirname "$installer")" && "$wine" "$installer")
  apply_registry # the installer may have just added the WebView2 services
  fl=$(find_fl)
  if [ -n "$fl" ]; then
    install_icon "$fl"
    say "installed: $fl"
  else
    say "FL64.exe not found under $WINEPREFIX; did the installer finish?"
  fi
  # The WebView2 installer leaves Edge's updater running, which would keep the
  # prefix alive for good; stop it unless the installer's last page started FL.
  stop_prefix_unless_busy fl
  ;;

--app)
  shift
  app=${1:?usage: fl-studio --app /path/to/program.exe}
  shift
  [ -f "$WINEPREFIX/system.reg" ] || die "no prefix yet; run 'fl-studio install INSTALLER.exe' first"
  redirect_logs_unless_tty "$(basename "$app" .exe)"
  cd "$(dirname "$app")" || exit 1
  "$wine" "$app" "$@"
  status=$?
  stop_prefix_unless_busy side
  exit $status
  ;;

--open)
  shift
  file=${1:?usage: fl-studio --open /path/to/file.exe}
  shift
  [ -f "$WINEPREFIX/system.reg" ] || die "no prefix yet; run 'fl-studio install INSTALLER.exe' first"
  name=$(basename "$file")
  redirect_logs_unless_tty "${name%.*}"
  cd "$(dirname "$file")" || exit 1
  "$wine" start /wait /unix "$file" "$@"
  status=$?
  stop_prefix_unless_busy side
  exit $status
  ;;

*://*)
  [ -f "$WINEPREFIX/system.reg" ] || die "no prefix yet; run 'fl-studio install INSTALLER.exe' first"
  redirect_logs_unless_tty link
  exec "$wine" start "$@"
  ;;

*)
  [ -f "$WINEPREFIX/system.reg" ] || die "no prefix yet; run 'fl-studio install INSTALLER.exe' first"
  fl=$(find_fl)
  [ -n "$fl" ] || die "FL Studio is not installed in $WINEPREFIX; run 'fl-studio install INSTALLER.exe'"
  redirect_logs_unless_tty FL64
  args=()
  for arg in "$@"; do
    if [ -e "$arg" ]; then
      args+=("$("$wine" winepath -w "$arg")")
    else
      args+=("$arg")
    fi
  done
  cd "$(dirname "$fl")" || exit 1
  "$wine" FL64.exe "${args[@]}"
  status=$?
  stop_prefix_unless_busy fl
  exit $status
  ;;
esac
