# VirtualHere USB Server (Jablotron F-Link)

Shares the USB of a Jablotron control panel (JA-100 / JA-100+) over the network so you
can connect to it remotely with **F-Link**. When stopped, the add-on returns the USB to
Home Assistant, so the `jablotron100` integration works again without a host reboot.

*SK: Zdieľa USB ústredne Jablotron cez sieť pre vzdialený F-Link. Po zastavení vráti USB
späť do HA bez reštartu hosta. Návod v slovenčine je v [MANUAL.sk.md](https://github.com/valdaaak/ha-jablotron-flink/blob/main/docs/MANUAL.sk.md).*

## Options

| Option | Default | Meaning |
| --- | --- | --- |
| `usb_vid` | `16d6` | USB Vendor ID of the panel (Jablotron) |
| `usb_pid` | `0008` | USB Product ID of the panel (JA-100 Flexi) |
| `server_name` | `HA-Jablotron` | Hub name shown in the VirtualHere client (letters, digits, space, `_`, `-`) |

Find the VID:PID in HA under **Settings → System → Hardware → All hardware** (search for `16d6`).

## Important

- **Leave Start on boot off.** Run the add-on only for an F-Link session (ideally via the blueprint from this repository).
- The server listens on **TCP 7575**. **Never expose that port to the internet**; access via VPN only.
- While it's running and a client has the device attached, the Jablotron integration has no connection to the panel.

Full guide: [MANUAL.md](https://github.com/valdaaak/ha-jablotron-flink/blob/main/docs/MANUAL.md)
