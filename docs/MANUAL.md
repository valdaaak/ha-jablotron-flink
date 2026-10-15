# Manual: Remote Jablotron F-Link via Home Assistant

This guide walks you through installation and everyday use. It assumes your Home
Assistant already has a Jablotron control panel connected via USB and the
`jablotron100` integration is working.

*Slovenská verzia: [MANUAL.sk.md](MANUAL.sk.md)*

## Contents

1. [How it works](#1-how-it-works)
2. [Requirements](#2-requirements)
3. [Installation in Home Assistant](#3-installation-in-home-assistant)
4. [VirtualHere client on Windows](#4-virtualhere-client-on-windows)
5. [Typical F-Link session](#5-typical-f-link-session)
6. [After the session: clearing problem sensors](#6-after-the-session-clearing-problem-sensors)
7. [Troubleshooting](#7-troubleshooting)
8. [Security](#8-security)
9. [Uninstalling](#9-uninstalling)

---

## 1. How it works

```text
 JA-100 panel ──USB──> Home Assistant ──[VirtualHere server, TCP 7575]──> VPN ──> PC
                       (jablotron100                                      (VirtualHere client
                        integration,                                       + F-Link)
                        /dev/hidraw0)
```

- **Normal operation:** the panel's USB belongs to the kernel (`usbhid`), which creates
  `/dev/hidraw0`, and the `jablotron100` integration reads from it.
- **F-Link mode (toggle ON):** the VirtualHere add-on starts. When the client on your PC
  attaches the device, VirtualHere unbinds the kernel driver and "moves" the USB over the
  network to the PC. F-Link then sees the panel as if it were plugged directly into the PC.
- **Return (toggle OFF):** VirtualHere does **not rebind** the kernel driver by itself, so
  `/dev/hidraw0` would stay gone until a host reboot. The add-on handles this: on both start
  and stop it runs a small tool, `usbreset`, which rebinds `usbhid` to both panel interfaces
  via `USBDEVFS_CONNECT`. The blueprint then reloads the integration.

> Why not `/sys/.../bind`? Inside an add-on, `/sys` is read-only (even with `full_access`).
> Only `/dev/bus/usb` is writable, and that is exactly what `USBDEVFS_CONNECT` uses.

## 2. Requirements

| What | Note |
| --- | --- |
| Home Assistant **OS** or **Supervised** | Add-ons are not available on Container/Core installs. |
| Jablotron panel connected to HA via **USB** | Tested with JA-100 Flexi (`16d6:0008`). |
| **Jablotron 100** integration (`jablotron100`) | Installed via HACS, not part of this repository. |
| **VPN** into the network where HA runs | WireGuard, OpenVPN, UniFi Teleport... anything works. |
| A **Windows** PC | Jablotron F-Link and the VirtualHere client. |

## 3. Installation in Home Assistant

### 3.1 Add the repository

1. **Settings → Add-ons → Add-on Store**
2. Top right **⋮ → Repositories**
3. Paste `https://github.com/valdaaak/ha-jablotron-flink` → **Add** → **Close**
4. Refresh the page (F5); a **Jablotron F-Link add-ons** section appears at the bottom.

### 3.2 Install the add-on

1. Open **VirtualHere USB Server (Jablotron F-Link)** → **Install**.
   Installation takes a few minutes because the add-on is built directly on your HA
   (it downloads the VirtualHere binary and compiles `usbreset`).
2. On the **Info** tab:
   - **Start on boot: OFF** (important, otherwise every HA start would take the USB away from the integration)
   - Watchdog: off
3. **Configuration** tab (defaults are for the JA-100 Flexi):

   | Option | Default | When to change |
   | --- | --- | --- |
   | `usb_vid` | `16d6` | practically never (Jablotron) |
   | `usb_pid` | `0008` | if your panel reports a different ID |
   | `server_name` | `HA-Jablotron` | any name (letters, digits, space, `_`, `-`) shown in the client |

   Check the ID under **Settings → System → Hardware → ⋮ All hardware**, search for `16d6`.

4. **Don't start** the add-on yet; the toggle will control it.

### 3.3 Create the toggle

1. **Settings → Devices & services → Helpers → Create helper → Toggle**
2. Name it e.g. `Jablotron F-Link server`, icon `mdi:usb-flash-drive`.
3. This creates an entity such as `input_boolean.jablotron_f_link_server`.

### 3.4 Import the blueprint and create the automation

1. **Settings → Automations & scenes → Blueprints → Import blueprint**
2. URL:
   `https://github.com/valdaaak/ha-jablotron-flink/blob/main/blueprints/automation/jablotron_flink_toggle.yaml`
3. On **Jablotron F-Link toggle (VirtualHere)** click **Create automation** and fill in:
   - **Toggle**: the helper from step 3.3
   - **VirtualHere add-on**: VirtualHere USB Server (Jablotron F-Link)
   - **Jablotron integration**: your panel
4. Save.

Add the toggle to a dashboard (tile or entities card).

## 4. VirtualHere client on Windows

1. Download the **VirtualHere USB Client** for Windows from
   [virtualhere.com/usb_client_software](https://www.virtualhere.com/usb_client_software)
   (`vhui64.exe`; no installation needed, it installs its driver on first run).
2. Connect to the **VPN**.
3. In the client: right-click **USB Hubs → Specify Hubs... → Add** → `YOUR_HA_IP:7575` → OK.
   (Bonjour auto-discovery usually doesn't work over VPN, so enter it manually.)
4. The hub only shows up while the **add-on is running** (toggle ON).

## 5. Typical F-Link session

| Step | Where | What |
| --- | --- | --- |
| 1 | HA | Toggle **ON**. The add-on is running within ~5–10 s. |
| 2 | PC | With VPN connected, the `HA-Jablotron` hub appears in the VirtualHere client. |
| 3 | PC | Right-click the Jablotron device → **Use this device**. Windows attaches it as a local USB device. |
| 4 | PC | Start **F-Link**, connect to the panel via USB and do your work. |
| 5 | PC | Close F-Link. In the client right-click → **Stop using this device**. |
| 6 | HA | Toggle **OFF**. The automation restarts the add-on (rebinds USB), stops it and reloads the integration. Takes ~10–15 s. |
| 7 | HA | Check that Jablotron entities are not `unavailable` (e.g. the alarm state). |

During steps 3–5 the HA integration has **no connection to the panel**. The alarm and
the panel keep working normally; HA just doesn't see them.

## 6. After the session: clearing problem sensors

While the USB was detached, the integration may have interpreted the lost communication
as faults. After the return, up to ~30 `binary_sensor.*problem_of_*` sensors can stay
"stuck" even though F-Link reports all devices as OK. These are latches in HA only.

Clear them with an action (Developer tools → Actions):

```yaml
action: jablotron100.reset_problem
target:
  entity_id: binary_sensor.problem_of_xxx   # or several entities at once
```

The action only changes state in HA; it writes nothing to the panel.

If you have automations that send notifications on faults or tamper events, consider
muting them during the F-Link session (e.g. with a condition "F-Link toggle is OFF").

## 7. Troubleshooting

**Add-on log:** Settings → Add-ons → VirtualHere → **Log**. On both start and stop it
should show:

```text
Found /sys/bus/usb/devices/1-1.3 -> /dev/bus/usb/001/004, rebinding kernel driver (USBDEVFS_CONNECT)
Connected driver to interface 0
Connected driver to interface 1
```

(`Interface N already has driver` is fine too.)

| Symptom | Cause | Fix |
| --- | --- | --- |
| After OFF the Jablotron integration is `unavailable` | `/dev/hidraw0` didn't come back or the integration hasn't picked it up yet | Check the add-on log. If it shows `Connected driver...`, a **Settings → System → Restart Home Assistant** (Core only) is enough. If it keeps happening, take control of the blueprint automation and replace the last step `homeassistant.reload_config_entry` with `homeassistant.restart`. |
| Log: `16d6:0008 NOT found in /sys` | Different USB ID or the panel isn't connected | Check the ID under Hardware and adjust `usb_vid`/`usb_pid`. |
| Log: `usbreset FAILED` | The add-on has no access to USB | Make sure the add-on comes from this repository (it has `usb: true`, `full_access: true`). If the add-on page has a *Protection mode* toggle, try turning it off and restarting the add-on. |
| Port 7575 opens briefly and closes again | Quick OFF → ON flip while USB was being returned | The blueprint handles this (`mode: restart` + state check). Wait 15 s and switch ON again. |
| Client doesn't see the hub | VPN, firewall, add-on not running | Check that the toggle is ON and the add-on is running, that `Test-NetConnection HA_IP -Port 7575` succeeds from the PC, and that the hub was added manually (Specify Hubs). |
| Client sees the hub but not the Jablotron device | USB ID mismatch or the device is held by another process | Check the add-on log and the ID. |
| Nothing helps | The kernel lost the device | As a last resort **Settings → System → ⋮ Reboot system** (host reboot) always brings the USB back. |

## 8. Security

- **Never port-forward TCP 7575 to the internet.** The VirtualHere server has no password.
  Anyone who reaches it gets physical-level access to the panel's USB. Access via VPN only.
- The add-on runs with `host_network`, `usb` and `full_access`. It needs these to see the
  USB device and rebind the driver. That's why it should run only for the F-Link session,
  with *Start on boot* left off.
- F-Link still requires the panel's service code. VirtualHere merely replaces the USB cable.

## 9. Uninstalling

1. Toggle OFF (USB returns to HA).
2. Delete the automation and the helper.
3. Settings → Add-ons → VirtualHere → **Uninstall**.
4. Optionally Add-on Store → ⋮ → Repositories → remove the repository.
