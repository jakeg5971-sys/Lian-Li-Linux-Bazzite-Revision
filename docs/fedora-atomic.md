# Fedora Atomic Edition

This project includes a dedicated Fedora Atomic workflow that keeps all original Lian Li Linux capabilities:

- Fan control (curves, fixed PWM, motherboard sync)
- RGB effects for wired and wireless controllers
- LCD media streaming (image, GIF, video, and sensor gauges)
- User-level daemon + GUI integration

## Supported Fedora Atomic Variants

- Silverblue
- Kinoite
- Sway Atomic
- Budgie Atomic
- COSMIC Atomic (when generally available)

## Why a Dedicated Atomic Workflow?

Fedora Atomic systems have an immutable `/usr`, so this workflow:

1. Layers only required host runtime packages with `rpm-ostree`.
2. Builds in a toolbox container so compilers and dev packages stay out of the host image.
3. Installs binaries and desktop entries in the user profile (`~/.local`).
4. Uses a user systemd service for daemon startup.

## Quick Install

From the repo root:

```bash
./scripts/fedora-atomic-bootstrap.sh
```

The script will:

- install host runtime dependencies,
- install udev permissions,
- create or reuse a toolbox,
- verify `libudev`/`libusb` discovery and run `cargo check`,
- compile release binaries,
- install the daemon and GUI in your user profile,
- enable and start `lianli-daemon`.

If `rpm-ostree` adds new packages, reboot once after the script finishes.

## Updating After Pulling New Changes

```bash
git pull
./scripts/fedora-atomic-bootstrap.sh
```

## Verifying Everything Works

```bash
systemctl --user status lianli-daemon
ls -la "$XDG_RUNTIME_DIR/lianli-daemon.sock"
```

Launch the GUI from your app menu (`Lian Li Linux`) or run:

```bash
~/.local/bin/lianli-gui
```
