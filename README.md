# Jablotron F-Link na diaľku cez Home Assistant

Ústredňa Jablotron JA-100 je pripojená USB k Home Assistantu (integrácia
[`jablotron100`](https://github.com/kukulich/home-assistant-jablotron100)).
Tento repozitár pridáva:

- **add-on VirtualHere USB Server**: na požiadanie zdieľa USB ústredne cez sieť,
  takže sa na ňu pripojíš programom **F-Link** z PC (cez VPN) a po skončení
  vráti USB späť do HA, **bez reštartu hosta**,
- **blueprint**: jeden prepínač v HA (ON = F-Link režim, OFF = späť do prevádzky).

[![Pridať repozitár do HA](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fvaldaaak%2Fha-jablotron-flink)
[![Importovať blueprint](https://my.home-assistant.io/badges/blueprint_import.svg)](https://my.home-assistant.io/redirect/blueprint_import/?blueprint_url=https%3A%2F%2Fgithub.com%2Fvaldaaak%2Fha-jablotron-flink%2Fblob%2Fmain%2Fblueprints%2Fautomation%2Fjablotron_flink_toggle.yaml)

**Návod krok za krokom: [docs/MANUAL.md](docs/MANUAL.md)**

## V skratke

1. Add-on Store → ⋮ → Repositories → `https://github.com/valdaaak/ha-jablotron-flink`
2. Nainštaluj **VirtualHere USB Server (Jablotron F-Link)**, *Start on boot* nechaj vypnuté.
3. Vytvor helper `input_boolean` (napr. „Jablotron F-Link server“).
4. Importuj blueprint, vytvor z neho automatizáciu (prepínač, add-on, integrácia Jablotron).
5. Prepínač ON → na PC klient VirtualHere → F-Link → po skončení prepínač OFF.

## Upozornenia

- Port **7575** nikdy nevystavuj na internet, len cez VPN.
- Bezplatný VirtualHere server zdieľa 1 USB zariadenie, čo na tento účel stačí. Licencia VirtualHere je vec používateľa.
- Po F-Link session môžu v HA zostať „zaseknuté“ senzory `problem_of_*`; vyčistí ich služba `jablotron100.reset_problem`.
- Testované: HAOS na Raspberry Pi (aarch64), Jablotron JA-100 Flexi (USB `16d6:0008`).

---

## English summary

Home Assistant add-on that shares a USB-connected Jablotron JA-100 control panel over
the network via VirtualHere, so you can use Jablotron **F-Link** remotely (over VPN).
On stop it rebinds the kernel HID driver (`USBDEVFS_CONNECT`), so `/dev/hidraw*` comes
back and the `jablotron100` integration recovers **without a host reboot**. A blueprint
turns it into a single `input_boolean` toggle. Never expose TCP 7575 to the internet.
Full guide (Slovak): [docs/MANUAL.md](docs/MANUAL.md).
