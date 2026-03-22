#!/usr/bin/env bash
set -euo pipefail

REMOVE_CONFIG=0
REMOVE_UDEV=0
REMOVE_TOOLBOX=0
REMOVE_PACKAGES=0
CONTAINER_NAME="${CONTAINER_NAME:-lianli-linux-builder}"

usage() {
  cat <<'USAGE'
Usage: ./scripts/uninstall-all-versions.sh [options]

Removes user-level Lian Li Linux installs from this machine, including files
created by older naming variants (lianli-* and lian-li-*).

Options:
  --purge-config      Remove ~/.config/lianli and ~/.cache/lianli
  --remove-udev       Remove matching udev rules from /etc/udev/rules.d
  --remove-toolbox    Remove the Fedora Atomic toolbox container
  --remove-packages   Try to uninstall distro packages (pacman / dnf)
  -h, --help          Show this help text
USAGE
}

log() {
  printf '\n[%s] %s\n' "$(date +%H:%M:%S)" "$*"
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

remove_file() {
  local path="$1"
  if [[ -e "$path" || -L "$path" ]]; then
    rm -f "$path"
    echo "removed $path"
  fi
}

remove_dir_if_empty() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  rmdir "$dir" 2>/dev/null || true
}

for arg in "$@"; do
  case "$arg" in
    --purge-config) REMOVE_CONFIG=1 ;;
    --remove-udev) REMOVE_UDEV=1 ;;
    --remove-toolbox) REMOVE_TOOLBOX=1 ;;
    --remove-packages) REMOVE_PACKAGES=1 ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      usage
      exit 1
      ;;
  esac
done

log "Stopping and disabling user services"
if have_cmd systemctl; then
  systemctl --user disable --now lianli-daemon.service 2>/dev/null || true
  systemctl --user disable --now lian-li-daemon.service 2>/dev/null || true
  systemctl --user daemon-reload || true
fi

log "Removing user-level binaries, desktop files, icons, and services"
remove_file "$HOME/.local/bin/lianli-daemon"
remove_file "$HOME/.local/bin/lianli-gui"
remove_file "$HOME/.local/bin/lian-li-daemon"
remove_file "$HOME/.local/bin/lian-li-gui"

remove_file "$HOME/.config/systemd/user/lianli-daemon.service"
remove_file "$HOME/.config/systemd/user/lian-li-daemon.service"
remove_file "$HOME/.local/share/systemd/user/lianli-daemon.service"
remove_file "$HOME/.local/share/systemd/user/lian-li-daemon.service"

remove_file "$HOME/.local/share/applications/lianli-gui.desktop"
remove_file "$HOME/.local/share/applications/lian-li-linux.desktop"
remove_file "$HOME/.local/share/applications/lian-li-gui.desktop"

remove_file "$HOME/.local/share/icons/hicolor/32x32/apps/lianli-gui.png"
remove_file "$HOME/.local/share/icons/hicolor/128x128/apps/lianli-gui.png"
remove_file "$HOME/.local/share/icons/hicolor/256x256/apps/lianli-gui.png"
remove_file "$HOME/.local/share/icons/hicolor/scalable/apps/lianli-gui.svg"
remove_file "$HOME/.local/share/icons/hicolor/32x32/apps/lian-li-linux.png"
remove_file "$HOME/.local/share/icons/hicolor/128x128/apps/lian-li-linux.png"
remove_file "$HOME/.local/share/icons/hicolor/256x256/apps/lian-li-linux.png"
remove_file "$HOME/.local/share/icons/hicolor/scalable/apps/lian-li-linux.svg"

for size in 32x32 128x128 256x256; do
  remove_dir_if_empty "$HOME/.local/share/icons/hicolor/$size/apps"
done
remove_dir_if_empty "$HOME/.local/share/icons/hicolor/scalable/apps"
remove_dir_if_empty "$HOME/.local/share/applications"
remove_dir_if_empty "$HOME/.local/share/systemd/user"
remove_dir_if_empty "$HOME/.config/systemd/user"

if have_cmd update-desktop-database; then
  update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
fi

if (( REMOVE_CONFIG )); then
  log "Removing config/cache"
  rm -rf "$HOME/.config/lianli" "$HOME/.cache/lianli"
fi

if (( REMOVE_UDEV )); then
  log "Removing udev rules"
  if [[ -f /etc/udev/rules.d/99-lianli.rules ]]; then
    sudo rm -f /etc/udev/rules.d/99-lianli.rules
  fi
  if [[ -f /etc/udev/rules.d/99-lian-li.rules ]]; then
    sudo rm -f /etc/udev/rules.d/99-lian-li.rules
  fi
  if have_cmd udevadm; then
    sudo udevadm control --reload-rules
    sudo udevadm trigger
  fi
fi

if (( REMOVE_TOOLBOX )); then
  if have_cmd toolbox; then
    log "Removing toolbox container: $CONTAINER_NAME"
    toolbox rm --force "$CONTAINER_NAME" || true
  else
    echo "toolbox command not found; skipping container removal"
  fi
fi

if (( REMOVE_PACKAGES )); then
  log "Attempting package uninstall"
  if have_cmd pacman; then
    sudo pacman -Rns --noconfirm lianli-linux-git lianli-linux 2>/dev/null || true
  fi

  if have_cmd dnf; then
    sudo dnf remove -y lianli-linux lianli-linux-git 2>/dev/null || true
  fi
fi

log "Uninstall complete"
if (( ! REMOVE_CONFIG )); then
  echo "Tip: rerun with --purge-config to remove ~/.config/lianli and ~/.cache/lianli"
fi
if (( ! REMOVE_UDEV )); then
  echo "Tip: rerun with --remove-udev to remove /etc/udev/rules.d/99-lianli.rules"
fi
if (( ! REMOVE_TOOLBOX )); then
  echo "Tip: rerun with --remove-toolbox to remove Fedora Atomic toolbox container"
fi
if (( ! REMOVE_PACKAGES )); then
  echo "Tip: rerun with --remove-packages to also uninstall distro packages if present"
fi
