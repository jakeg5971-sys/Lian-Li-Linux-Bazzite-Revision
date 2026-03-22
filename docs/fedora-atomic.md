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

> If you see "pending deployment" or updates are "not active yet", reboot first and rerun the bootstrap script:
>
> ```bash
> systemctl reboot
> ./scripts/fedora-atomic-bootstrap.sh
> ```

## Updating After Pulling New Changes

```bash
git pull
./scripts/fedora-atomic-bootstrap.sh
```

## Uninstall

From the repo root:

```bash
./scripts/uninstall-all-versions.sh --remove-udev --remove-toolbox --purge-config
```

This removes user binaries/integration files and can also remove Atomic-specific udev/toolbox/config artifacts.

## Verifying Everything Works

```bash
systemctl --user status lianli-daemon
ls -la "$XDG_RUNTIME_DIR/lianli-daemon.sock"
```

Launch the GUI from your app menu (`Lian Li Linux`) or run:

```bash
~/.local/bin/lianli-gui
```

## Troubleshooting: Atomic updates not becoming active

On Fedora Atomic, layered package changes from `rpm-ostree` only apply after booting into the new deployment.

Check whether a deployment is pending:

```bash
rpm-ostree status --pending-exit-77
echo $?
```

- `0` means there is no pending deployment.
- `77` means updates are staged but inactive; reboot is required.

If it returns `77`, run:

```bash
systemctl reboot
```

After reboot, run `./scripts/fedora-atomic-bootstrap.sh` again.
