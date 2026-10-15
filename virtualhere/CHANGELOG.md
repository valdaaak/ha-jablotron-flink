# Changelog

## 1.5.1
- English log messages, add-on docs, blueprint and manual (`docs/MANUAL.en.md`); Slovak manual kept.
- `server_name` restricted to letters, digits, space, `_` and `-`.

## 1.5.0
- First public release.
- USB VID, PID and server name configurable in the add-on options.

## 1.4.0
- Kernel driver is rebound via `USBDEVFS_CONNECT` on both start and stop (`/dev/hidraw*` comes back without a host reboot).

## 1.0.0
- VirtualHere server for Jablotron USB control panels.
