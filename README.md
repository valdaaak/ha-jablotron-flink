# Jablotron F-Link na diaľku cez Home Assistant

**[English below](#english)** · Manuál: [slovensky](docs/MANUAL.md) · [English](docs/MANUAL.en.md)

[![Pridať repozitár do HA / Add repository to HA](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fvaldaaak%2Fha-jablotron-flink)
[![Importovať blueprint / Import blueprint](https://my.home-assistant.io/badges/blueprint_import.svg)](https://my.home-assistant.io/redirect/blueprint_import/?blueprint_url=https%3A%2F%2Fgithub.com%2Fvaldaaak%2Fha-jablotron-flink%2Fblob%2Fmain%2Fblueprints%2Fautomation%2Fjablotron_flink_toggle.yaml)

Ústredňa Jablotron JA-100 je pripojená USB k Home Assistantu (integrácia
[`jablotron100`](https://github.com/kukulich/home-assistant-jablotron100)).
Tento repozitár pridáva:

- **add-on VirtualHere USB Server**: na požiadanie zdieľa USB ústredne cez sieť,
  takže sa na ňu pripojíš programom **F-Link** z PC (cez VPN) a po skončení
  vráti USB späť do HA, **bez reštartu hosta**,
- **blueprint**: jeden prepínač v HA (ON = F-Link režim, OFF = späť do prevádzky).

**Návod krok za krokom: [docs/MANUAL.md](docs/MANUAL.md)**

### V skratke

1. Add-on Store → ⋮ → Repositories → `https://github.com/valdaaak/ha-jablotron-flink`
2. Nainštaluj **VirtualHere USB Server (Jablotron F-Link)**, *Start on boot* nechaj vypnuté.
3. Vytvor helper `input_boolean` (napr. „Jablotron F-Link server“).
4. Importuj blueprint, vytvor z neho automatizáciu (prepínač, add-on, integrácia Jablotron).
5. Prepínač ON → na PC klient VirtualHere → F-Link → po skončení prepínač OFF.

### Upozornenia

- Port **7575** nikdy nevystavuj na internet, len cez VPN.
- Bezplatný VirtualHere server zdieľa 1 USB zariadenie, čo na tento účel stačí. Licencia VirtualHere je vec používateľa.
- Po F-Link session môžu v HA zostať „zaseknuté“ senzory `problem_of_*`; vyčistí ich služba `jablotron100.reset_problem`.
- Testované: HAOS na Raspberry Pi (aarch64), Jablotron JA-100 Flexi (USB `16d6:0008`).

---

<a id="english"></a>

## English

Your Jablotron JA-100 control panel is connected to Home Assistant via USB (integration
[`jablotron100`](https://github.com/kukulich/home-assistant-jablotron100)).
This repository adds:

- **VirtualHere USB Server add-on**: on demand, shares the panel's USB over the network
  so you can connect to it with Jablotron **F-Link** from your PC (over VPN), and afterwards
  returns the USB to HA **without a host reboot**,
- **a blueprint**: a single toggle in HA (ON = F-Link mode, OFF = back to normal operation).

**Step-by-step guide: [docs/MANUAL.en.md](docs/MANUAL.en.md)**

### Quick start

1. Add-on Store → ⋮ → Repositories → `https://github.com/valdaaak/ha-jablotron-flink`
2. Install **VirtualHere USB Server (Jablotron F-Link)**; leave *Start on boot* off.
3. Create an `input_boolean` helper (e.g. "Jablotron F-Link server").
4. Import the blueprint and create an automation from it (toggle, add-on, Jablotron integration).
5. Toggle ON → VirtualHere client on your PC → F-Link → toggle OFF when done.

### Why this exists

When VirtualHere takes over a USB device it unbinds the kernel HID driver, and it doesn't
rebind it on release, so `/dev/hidraw0` disappears and the integration stays dead until a
host reboot. Inside an add-on `/sys` is read-only, so the usual `bind` trick doesn't work.
This add-on rebinds the driver through usbfs (`USBDEVFS_CONNECT` on `/dev/bus/usb/...`)
on every start and stop.

### Notes

- Never expose port **7575** to the internet; use a VPN.
- The free VirtualHere server shares one USB device, which is enough here. VirtualHere licensing is up to you.
- After an F-Link session some `problem_of_*` sensors may stay latched in HA; clear them with `jablotron100.reset_problem`.
- Tested on HAOS on a Raspberry Pi (aarch64) with a Jablotron JA-100 Flexi (USB `16d6:0008`).

## License

MIT for the files in this repository. The VirtualHere server binary is downloaded from
virtualhere.com at build time and is covered by VirtualHere's own license.
