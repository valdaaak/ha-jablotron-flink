# VirtualHere USB Server (Jablotron F-Link)

Zdieľa USB ústredne Jablotron (JA-100 / JA-100+) cez sieť, aby sa dalo na diaľku
pripojiť programom **F-Link**. Po zastavení add-on vráti USB späť Home Assistantu,
takže integrácia `jablotron100` znova funguje bez reštartu hosta.

## Nastavenia

| Voľba | Predvolené | Význam |
| --- | --- | --- |
| `usb_vid` | `16d6` | USB Vendor ID ústredne (Jablotron) |
| `usb_pid` | `0008` | USB Product ID ústredne (JA-100 Flexi) |
| `server_name` | `HA-Jablotron` | Názov hubu, ktorý uvidíš v klientovi VirtualHere |

VID:PID zistíš v HA: **Settings → System → Hardware → All hardware** (hľadaj `16d6`).

## Dôležité

- **Start on boot nechaj vypnuté.** Add-on sa zapína len na F-Link session (ideálne cez blueprint z repa).
- Server počúva na **TCP 7575**. Ten port **nikdy nevystavuj na internet** — prístup len cez VPN.
- Kým beží a klient má USB pripojené, integrácia Jablotron nemá spojenie s ústredňou.

Kompletný návod: [MANUAL.md](https://github.com/valdaaak/ha-jablotron-flink/blob/main/docs/MANUAL.md)
