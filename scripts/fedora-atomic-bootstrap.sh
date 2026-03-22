#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="${CONTAINER_NAME:-lianli-linux-builder}"
FEDORA_RELEASE="${FEDORA_RELEASE:-42}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() {
  printf '\n[%s] %s\n' "$(date +%H:%M:%S)" "$*"
}

warn() {
  printf '\n[WARN] %s\n' "$*" >&2
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Error: required command '$1' is not installed." >&2
    exit 1
  }
}

pending_ostree_deployment() {
  set +e
  rpm-ostree status --pending-exit-77 >/dev/null 2>&1
  local rc=$?
  set -e
  case "$rc" in
    0) return 1 ;;
    77) return 0 ;;
    *)
      warn "Unable to determine rpm-ostree pending deployment status (exit code: $rc)."
      return 1
      ;;
  esac
}

for cmd in rpm-ostree toolbox systemctl cargo; do
  need_cmd "$cmd"
done

if [[ ! -f /run/ostree-booted ]]; then
  echo "This installer is designed for Fedora Atomic variants (ostree systems)." >&2
  exit 1
fi

if pending_ostree_deployment; then
  warn "A pending rpm-ostree deployment is already staged but not active."
  warn "Reboot first so layered packages are active, then rerun this script."
  warn "Suggested command: systemctl reboot"
  exit 1
fi

log "Layering host dependencies (requires reboot if new packages are applied)"
sudo rpm-ostree install \
  hidapi libusb1 ffmpeg fontconfig \
  libxkbcommon wayland libX11 libinput libdrm \
  mesa-libGL mesa-libEGL clang cmake pkg-config systemd-devel || true

log "Installing udev access rule"
sudo install -D -m 0644 "$REPO_DIR/udev/99-lianli.rules" /etc/udev/rules.d/99-lianli.rules
sudo udevadm control --reload-rules
sudo udevadm trigger

log "Ensuring toolbox container '$CONTAINER_NAME' exists"
if ! toolbox list --containers | awk '{print $1}' | grep -qx "$CONTAINER_NAME"; then
  toolbox create --container "$CONTAINER_NAME" --image "registry.fedoraproject.org/fedora-toolbox:${FEDORA_RELEASE}"
fi

log "Installing build dependencies in toolbox"
toolbox run --container "$CONTAINER_NAME" bash -lc '
  set -euo pipefail
  sudo dnf -y install \
    hidapi-devel libusb1-devel fontconfig-devel \
    libxkbcommon-devel wayland-devel libX11-devel libinput-devel libdrm-devel \
    mesa-libGL-devel mesa-libEGL-devel clang cmake pkg-config ffmpeg systemd-devel

  pkg-config --exists libudev
  pkg-config --exists libusb-1.0
'

log "Running cargo check in toolbox"
toolbox run --container "$CONTAINER_NAME" bash -lc "
  set -euo pipefail
  cd '$REPO_DIR'
  cargo check
"

log "Building release binaries in toolbox"
toolbox run --container "$CONTAINER_NAME" bash -lc "
  set -euo pipefail
  cd '$REPO_DIR'
  cargo build --release
"

log "Installing binaries and desktop integration to the user profile"
install -D -m 0755 "$REPO_DIR/target/release/lianli-daemon" "$HOME/.local/bin/lianli-daemon"
install -D -m 0755 "$REPO_DIR/target/release/lianli-gui" "$HOME/.local/bin/lianli-gui"

for size in 32x32 128x128 256x256; do
  mkdir -p "$HOME/.local/share/icons/hicolor/$size/apps"
done
install -m 0644 "$REPO_DIR/assets/icons/32x32.png" "$HOME/.local/share/icons/hicolor/32x32/apps/lianli-gui.png"
install -m 0644 "$REPO_DIR/assets/icons/128x128.png" "$HOME/.local/share/icons/hicolor/128x128/apps/lianli-gui.png"
install -m 0644 "$REPO_DIR/assets/icons/128x128@2x.png" "$HOME/.local/share/icons/hicolor/256x256/apps/lianli-gui.png"
install -D -m 0644 "$REPO_DIR/lianli-gui.desktop" "$HOME/.local/share/applications/lianli-gui.desktop"

log "Installing and enabling user daemon service"
install -D -m 0644 "$REPO_DIR/systemd/lianli-daemon.service" "$HOME/.config/systemd/user/lianli-daemon.service"
systemctl --user daemon-reload
systemctl --user enable --now lianli-daemon

if pending_ostree_deployment; then
  warn "rpm-ostree has staged a new deployment that is not active yet."
  warn "Please reboot now to activate the updates: systemctl reboot"
else
  log "Done. No pending rpm-ostree deployment detected."
fi
