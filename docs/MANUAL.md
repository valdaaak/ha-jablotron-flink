# Manuál: Jablotron F-Link na diaľku cez Home Assistant

Tento návod ťa prevedie inštaláciou a bežným použitím. Počíta s tým, že HA už má
ústredňu Jablotron pripojenú USB a integrácia `jablotron100` funguje.

*English version: [MANUAL.en.md](MANUAL.en.md)*

## Obsah

1. [Ako to funguje](#1-ako-to-funguje)
2. [Požiadavky](#2-požiadavky)
3. [Inštalácia v Home Assistante](#3-inštalácia-v-home-assistante)
4. [Klient VirtualHere na Windows](#4-klient-virtualhere-na-windows)
5. [Bežný postup: F-Link session](#5-bežný-postup-f-link-session)
6. [Po session: upratanie porúch](#6-po-session-upratanie-porúch)
7. [Riešenie problémov](#7-riešenie-problémov)
8. [Bezpečnosť](#8-bezpečnosť)
9. [Odinštalovanie](#9-odinštalovanie)

---

## 1. Ako to funguje

```text
 Ústredňa JA-100 ──USB──> Home Assistant ──[VirtualHere server, TCP 7575]──> VPN ──> PC
                          (integrácia                                        (VirtualHere klient
                           jablotron100,                                      + F-Link)
                           /dev/hidraw0)
```

- **Bežná prevádzka:** USB ústredne patrí kernelu (`usbhid`), vznikne `/dev/hidraw0`
  a z neho číta integrácia `jablotron100`.
- **F-Link režim (prepínač ON):** spustí sa add-on VirtualHere. Keď sa klient na PC
  pripojí k zariadeniu, VirtualHere odviaže kernel driver a USB „presunie“ cez sieť na PC.
  F-Link potom vidí ústredňu, akoby bola pripojená priamo k PC.
- **Návrat (prepínač OFF):** VirtualHere sám od seba kernel driver **nenaviaže späť**,
  takže `/dev/hidraw0` by ostal preč až do reštartu hosta. Add-on to rieši sám: pri štarte
  aj stope zavolá malý nástroj `usbreset`, ktorý cez `USBDEVFS_CONNECT` naviaže `usbhid`
  späť na obe rozhrania ústredne. Potom blueprint znova načíta integráciu.

> Prečo nie cez `/sys/.../bind`? V add-one je `/sys` iba na čítanie (aj pri `full_access`).
> Zapisovateľné je len `/dev/bus/usb`, a cez neho ide práve `USBDEVFS_CONNECT`.

## 2. Požiadavky

| Čo | Poznámka |
| --- | --- |
| Home Assistant **OS** alebo **Supervised** | Add-ony v Container/Core inštalácii nefungujú. |
| Ústredňa Jablotron pripojená **USB** do HA | Overené na JA-100 Flexi (`16d6:0008`). |
| Integrácia **Jablotron 100** (`jablotron100`) | Inštaluje sa cez HACS, nie je súčasťou tohto repa. |
| **VPN** do siete, kde je HA | WireGuard, OpenVPN, UniFi Teleport... čokoľvek. |
| PC s **Windows** | F-Link od Jablotronu a klient VirtualHere. |

## 3. Inštalácia v Home Assistante

### 3.1 Pridať repozitár

1. **Settings → Add-ons → Add-on Store**
2. Vpravo hore **⋮ → Repositories**
3. Vlož `https://github.com/valdaaak/ha-jablotron-flink` → **Add** → **Close**
4. Obnov stránku (F5), dole sa objaví sekcia **Jablotron F-Link add-ons**.

### 3.2 Nainštalovať add-on

1. Otvor **VirtualHere USB Server (Jablotron F-Link)** → **Install**.
   Inštalácia trvá pár minút, add-on sa zostavuje priamo na tvojom HA
   (stiahne binárku VirtualHere a skompiluje `usbreset`).
2. Na karte **Info**:
   - **Start on boot: VYPNUTÉ** (dôležité, inak by si pri každom štarte HA bral integrácii USB)
   - Watchdog: vypnutý
3. Karta **Configuration** (predvolené hodnoty sú pre JA-100 Flexi):

   | Voľba | Predvolené | Kedy meniť |
   | --- | --- | --- |
   | `usb_vid` | `16d6` | prakticky nikdy (Jablotron) |
   | `usb_pid` | `0008` | ak má tvoja ústredňa iné ID |
   | `server_name` | `HA-Jablotron` | názov v klientovi (písmená, číslice, medzera, `_`, `-`) |

   ID overíš v **Settings → System → Hardware → ⋮ All hardware**, hľadaj `16d6`.

4. Add-on **zatiaľ nespúšťaj**, bude ho ovládať prepínač.

### 3.3 Vytvoriť prepínač

1. **Settings → Devices & services → Helpers → Create helper → Toggle**
2. Názov napr. `Jablotron F-Link server`, ikona `mdi:usb-flash-drive`.
3. Vznikne entita napr. `input_boolean.jablotron_f_link_server`.

### 3.4 Importovať blueprint a vytvoriť automatizáciu

1. **Settings → Automations & scenes → Blueprints → Import blueprint**
2. URL:
   `https://github.com/valdaaak/ha-jablotron-flink/blob/main/blueprints/automation/jablotron_flink_toggle.yaml`
3. Pri blueprinte **Jablotron F-Link toggle (VirtualHere)** klikni **Create automation** a vyplň:
   - **Toggle**: helper z kroku 3.3
   - **VirtualHere add-on**: VirtualHere USB Server (Jablotron F-Link)
   - **Jablotron integration**: tvoja ústredňa
4. Ulož.

Prepínač si pridaj na dashboard (dlaždica alebo entity karta).

## 4. Klient VirtualHere na Windows

1. Stiahni **VirtualHere USB Client** pre Windows z
   [virtualhere.com/usb_client_software](https://www.virtualhere.com/usb_client_software)
   (`vhui64.exe`, netreba inštalovať, pri prvom spustení doinštaluje ovládač).
2. Pripoj sa na **VPN**.
3. V klientovi: pravý klik na **USB Hubs → Specify Hubs... → Add** → `IP_tvojho_HA:7575` → OK.
   (Automatické vyhľadávanie cez Bonjour cez VPN väčšinou nejde, preto zadať ručne.)
4. Hub sa zobrazí, až keď **beží add-on** (prepínač ON).

## 5. Bežný postup: F-Link session

| Krok | Kde | Čo |
| --- | --- | --- |
| 1 | HA | Prepínač **ON**. Za cca 5–10 s beží add-on. |
| 2 | PC | VPN pripojená, v klientovi VirtualHere sa objaví hub `HA-Jablotron`. |
| 3 | PC | Pravý klik na zariadenie Jablotron → **Use this device**. Windows ho „pripojí“ ako lokálne USB. |
| 4 | PC | Spusti **F-Link**, pripoj sa na ústredňu cez USB a urob, čo treba. |
| 5 | PC | Zavri F-Link. V klientovi pravý klik → **Stop using this device**. |
| 6 | HA | Prepínač **OFF**. Automatizácia reštartuje add-on (naviaže USB späť), zastaví ho a znova načíta integráciu. Trvá cca 10–15 s. |
| 7 | HA | Skontroluj, že entity Jablotronu nie sú `unavailable` (napr. stav alarmu). |

Počas krokov 3–5 integrácia v HA **nemá spojenie s ústredňou**. Alarm a ústredňa pritom
fungujú normálne, len HA o nich nevie.

## 6. Po session: upratanie porúch

Kým bolo USB odpojené, integrácia mohla vyhodnotiť výpadok komunikácie ako poruchy.
Po návrate tak môže zostať „zaseknutých“ aj ~30 senzorov `binary_sensor.*problem_of_*`,
hoci F-Link hlási všetky zariadenia v poriadku. Sú to latche iba v HA.

Vyčistíš ich službou (Developer tools → Actions):

```yaml
action: jablotron100.reset_problem
target:
  entity_id: binary_sensor.problem_of_xxx   # alebo viac entít naraz
```

Služba mení iba stav v HA, do ústredne nezapisuje nič.

Ak máš automatizácie, ktoré na poruchy či sabotáže posielajú notifikácie, oplatí sa ich
počas F-Link session stlmiť (napr. podmienkou „prepínač F-Link je OFF“).

## 7. Riešenie problémov

**Log add-onu:** Settings → Add-ons → VirtualHere → **Log**. Pri štarte aj stope v ňom
musí byť:

```text
Found /sys/bus/usb/devices/1-1.3 -> /dev/bus/usb/001/004, rebinding kernel driver (USBDEVFS_CONNECT)
Connected driver to interface 0
Connected driver to interface 1
```

(`Interface N already has driver` je tiež v poriadku.)

| Príznak | Príčina | Riešenie |
| --- | --- | --- |
| Po OFF je integrácia Jablotron `unavailable` | `/dev/hidraw0` sa nevrátil alebo integrácia ho ešte nechytila | Pozri log add-onu. Ak je tam `Connected driver...`, stačí **Settings → System → Restart Home Assistant** (len Core). Ak sa to opakuje, v automatizácii (Take control blueprintu) nahraď posledný krok `homeassistant.reload_config_entry` za `homeassistant.restart`. |
| Log: `16d6:0008 NOT found in /sys` | Iné USB ID alebo ústredňa nie je pripojená | Over ID v Hardware a uprav `usb_vid`/`usb_pid`. |
| Log: `usbreset FAILED` | Add-on nemá prístup k USB | Over, že add-on je z tohto repa (má `usb: true`, `full_access: true`). Ak má karta add-onu prepínač *Protection mode*, skús ho vypnúť a add-on reštartovať. |
| Port 7575 sa na chvíľu otvorí a hneď zavrie | Rýchle prepnutie OFF → ON počas návratu | Blueprint to ošetruje (`mode: restart` + kontrola stavu). Počkaj 15 s a prepni ON znova. |
| Klient nevidí hub | VPN, firewall, add-on nebeží | Over, že prepínač je ON a add-on beží, že z PC funguje `Test-NetConnection IP_HA -Port 7575` a hub je zadaný ručne (Specify Hubs). |
| Klient vidí hub, ale nie zariadenie Jablotron | USB ID nesedí alebo zariadenie drží iný proces | Pozri log add-onu, over ID. |
| Nič nepomáha | Kernel stratil zariadenie | Núdzovo **Settings → System → ⋮ Reboot system** (reštart hosta) USB vždy vráti. |

## 8. Bezpečnosť

- **TCP 7575 nikdy nesmeruj (port forward) na internet.** VirtualHere server nemá heslo.
  Kto sa naň dostane, má fyzický prístup k USB ústredne. Prístup iba cez VPN.
- Add-on beží s `host_network`, `usb` a `full_access`. Potrebuje to, aby videl USB
  zariadenie a mohol naviazať driver. Preto ho spúšťaj len na čas F-Link session a
  *Start on boot* nechaj vypnuté.
- F-Link aj tak vyžaduje servisný kód ústredne. VirtualHere iba nahrádza USB kábel.

## 9. Odinštalovanie

1. Prepínač OFF (USB sa vráti HA).
2. Zmaž automatizáciu a helper.
3. Settings → Add-ons → VirtualHere → **Uninstall**.
4. Voliteľne Add-on Store → ⋮ → Repositories → odstráň repozitár.
