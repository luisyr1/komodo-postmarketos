# Milestone 5: Bluetooth (Broadcom BCM4390) / Hito 5: Bluetooth (Broadcom BCM4390)

Reached on our unit on 2026-11-25 (see [JOURNAL.md](JOURNAL.md)). This is a
reproducible description of what we did on top of
[Milestone 4](MILESTONE-4.md): kernel package `linux-google-zumapro`
`pkgrel=4` (15 patches; the new ones are 0014 and 0015, plus three Bluetooth
options in the config), device package `device-google-komodo` unchanged at
`pkgrel=3`, and the Bluetooth firmware taken from the owner's own factory
image. `hci0` comes up at boot, BlueZ powers it, it scans, and it paired and
connected with a phone from Phosh's settings while WiFi stayed connected.

It is **not** finished Bluetooth support: the controller runs with the
chip's default address (the same on every unconfigured BCM4390), Bluetooth
audio cannot be tested because the phone has no audio yet, and suspend,
long idle periods, specific profiles (HID, A2DP, tethering) and the stock
4 Mbaud link speed were not tried. Everything was verified once, on one
unit.

Alcanzado en nuestra unidad el 2026-11-25 (ver [JOURNAL.md](JOURNAL.md)).
Descripción reproducible de lo que hicimos sobre el [hito 4](MILESTONE-4.md):
paquete del kernel `linux-google-zumapro` `pkgrel=4` (15 parches; los nuevos
son 0014 y 0015, más tres opciones de Bluetooth en la config), paquete del
dispositivo `device-google-komodo` sin cambios en `pkgrel=3`, y el firmware
Bluetooth sacado de la imagen de fábrica del propio dueño. `hci0` aparece al
arrancar, BlueZ lo enciende, escanea, y se emparejó y conectó con un
teléfono desde los ajustes de Phosh con el WiFi conectado a la vez.

**No** es un soporte Bluetooth terminado: el controlador usa la dirección
por defecto del chip (la misma en todo BCM4390 sin configurar), el audio por
Bluetooth no se puede probar porque el teléfono aún no tiene audio, y no se
han probado suspensión, reposo prolongado, perfiles concretos (HID, A2DP,
compartir conexión) ni la velocidad de 4 Mbaud de fábrica. Todo se comprobó
una vez, en una unidad.

> **The firmware is proprietary and is not in this repository.** It belongs
> to Broadcom/Google and comes with no redistribution license we know of.
> You extract it from the factory image of **your own** phone's build
> (step 4). Do not publish it, do not commit it, do not package it in a
> public repository.
>
> **Patches 0014 and 0015 are not upstream and have not been sent
> anywhere.** Like the rest of this repository they were written with AI
> assistance; [Nura's AI policy](https://docs.nura.eco/policies-and-processes/development/ai-policy.html)
> does not accept that, so do not submit them to Nura or to the kernel as
> is.
>
> **Every BCM4390 left unconfigured shares the same default address.** Two
> such phones near each other could clash. Setting a proper address is still
> open (step 13).
>
> **El firmware es propietario y no está en este repositorio:** sácalo de la
> imagen de fábrica del build de **tu** teléfono y no lo publiques. **Los
> parches 0014 y 0015 no están en upstream ni se han enviado:** están hechos
> con asistencia de IA, como el resto del repo. **Todo BCM4390 sin
> configurar comparte la misma dirección por defecto:** dos teléfonos así
> cerca podrían chocar; darle una dirección propia sigue pendiente.

[English](#english) · [Español](#español)

---

## English

### Before you start

- Everything in [MILESTONE-4.md](MILESTONE-4.md#before-you-start) applies,
  and Milestone 4 should already work on your unit.
- **No reinstall:** this milestone does not reflash `userdata`. Only
  `boot_b`, `vendor_boot_b` and `vendor_kernel_boot_b` change, as in
  [MILESTONE-3.md step 9](MILESTONE-3.md#9-updating-the-kernel-without-reinstalling).
- BlueZ on the phone: `bluetoothctl` and the `bluetooth` service, and
  `btmgmt` for the checks in step 10 (on Alpine-based systems `btmgmt` is
  packaged separately, as `bluez-btmgmt`).
- **No warranty.** We did this on one unit, once.

### 1. Inputs

| Item | Value |
|---|---|
| Kernel package | `linux-google-zumapro` `pkgrel=4`: same source commit `ffd33b7ddc716eb3568fff9f8d337a4032d109eb`, 15 patches ([`../pmaports/device/testing/linux-google-zumapro/`](../pmaports/device/testing/linux-google-zumapro/)) |
| Device package | `device-google-komodo` `pkgrel=3`, unchanged since Milestone 3 |
| Resulting `uname -r` | `7.3.0-rc6-zumapro` |
| Kernel config | `CONFIG_BT_LE=y`, `CONFIG_BT_RFCOMM=m`, `CONFIG_BT_RFCOMM_TTY=y` are new (`CONFIG_BT_LE_L2CAP_ECRED=y` follows from `BT_LE` by default). `BT_HCIUART` with serdev and the Broadcom protocol, `BT_BCM`, BNEP and HIDP were already set |
| Firmware | factory image `CP4A.261105.040.A1`, `vendor.img`, `/vendor/firmware/brcm/BCM_200.hcd` (step 4); not redistributed |
| Firmware install | [`../scripts/install-bt-firmware.sh`](../scripts/install-bt-firmware.sh) |
| Images | [`../scripts/mkimages-pmos.sh`](../scripts/mkimages-pmos.sh), unchanged |

### 2. The hardware

| Item | Value |
|---|---|
| Chip | the Bluetooth half of the Broadcom BCM4390 combo (the WiFi half is on PCIe, Milestone 4) |
| Silicon | `BCM4390B1` as reported by the ROM: B1, the same revision as the WiFi side |
| UART | USI1 of the APM at `0x155d0000` (stock `serial_18`); `ttySAC0` under Linux, as the only UART enabled |
| Power | `BT_REG_ON` on `gpn8-0`, held by a flip-flop clocked by `gpp24-3` (`brcm,ble-dbo`, as on the Pixel 9a and Pixel 8 Pro) |
| Wake lines | `BT_DEV_WAKE` on `gpn9-0`; `BT_HOST_WAKE` on `gpa5-6`, rising edge, pulled down |
| UART pads | no pinctrl: stock describes none for this UART, and on `komodo` the `gpa3` pads that zuma's `uart18_bus` would claim carry another function (the modem PMIC's bit-banged SPMI in the stock DTBO) |

These come from the stock DTB and DTBO (entry 34) and the stock Bluetooth
HAL configuration; see [DEVICE.md](DEVICE.md).

### 3. What the patches change

| Patch | What it does | Status on our unit |
|---|---|---|
| 0014 | DTS: enables `cmu_peric1`, `pinctrl_peric1` (`gpp24`), `pinctrl_far_alive` with `gpa5`'s interrupts, `usi_apm1` and `uart18`, and adds the `bluetooth` node (`brcm,bcm4390-bt`, `brcm,bcm4389-bt`) with the pins above, `max-speed = <3000000>` | works: `serial0-0` appears, `hci_uart` autoloads from it |
| 0015 | `hci_bcm`: adds `brcm,bcm4390-bt` with a 100 ms `BT_REG_ON` power-on delay (the stock HAL's value; the BCM4389 entry uses 30 ms), and the matching binding change | works: chip powers up, firmware patch loads |

0014 keeps `brcm,bcm4389-bt` as a fallback, so the node also works on a
kernel without 0015 (with the BCM4389's 30 ms delay); we did not test that
combination. `btbcm` needs no change: the BCM4390 is not in its name table,
so it asks for `brcm/BCM.<root compatible>.hcd`, here
`brcm/BCM.google,zumapro-komodo.hcd`, and then `brcm/BCM.hcd`.

The commit messages of 0014 and 0015 still say "Not tested on hardware" and
ask to keep `hci_uart` blacklisted. They are kept as they were built (only
the `From:` line was normalised for publication, with the checksums
updated); this document is the current state.

### 4. Get the firmware from your own factory image

As in [MILESTONE-4.md step 4](MILESTONE-4.md#4-get-the-firmware-from-your-own-factory-image),
from the factory image of the **build installed on your phone**, in a
private directory outside this repository. The file is
`/firmware/brcm/BCM_200.hcd` inside `vendor.img` (`/vendor/firmware/brcm/`
on Android); with an ext4 `vendor.img`, without root:

```sh
mkdir -p "$KOMODO_WORK/firmware/vendor-firmware/brcm"
debugfs -R "dump /firmware/brcm/BCM_200.hcd $KOMODO_WORK/firmware/vendor-firmware/brcm/BCM_200.hcd" vendor.img
```

Delete `vendor.img` when done.

`BCM_200.hcd` is the file the stock Bluetooth HAL loads (its
`firmware_config.json` names it). Its header names `BCM4390B1`, matching the
ROM. The same directory holds a `BCM.hcd` that the stock configuration does
not reference; the script's `--alt` stages that one instead. We never needed
it.

| Factory file (`/vendor/firmware/brcm`) | Size | SHA-256 | Name for btbcm |
|---|---|---|---|
| `BCM_200.hcd` | 818034 | `e716e8ef48865fa99f26a50bdaa1390c3bdca5688579845513e6b97341009ce5` | `BCM.google,zumapro-komodo.hcd` |
| `BCM.hcd` (fallback, unused) | 829025 | `7c907205db9c9cae9ec704f534518a1cc892507ae7eac63fb772c660483ff3ee` | same, with `--alt` |

These are public files from Google's image of `CP4A.261105.040.A1`; they do
not identify a unit. On the phone the file goes to
`/lib/firmware/updates/brcm/`.

### 5. Blacklist before the first boot of the new kernel

With 0014 in the DTB, udev loads `hci_uart` from the node's modalias at
boot, and the Bluetooth core powers the chip and downloads the firmware
straight away, without BlueZ. For the first boot, keep that from happening.
On the phone, **before** booting the new kernel:

```sh
echo 'blacklist hci_uart' | sudo tee /etc/modprobe.d/komodo-bt.conf
```

`modprobe hci_uart` by hand still works with it. You remove it in step 9.

### 6. Build and install the kernel without reinstalling

As in [MILESTONE-4.md step 6](MILESTONE-4.md#6-build-and-install-the-kernel-without-reinstalling):
refresh your pmaports copy with this repository's `linux-google-zumapro`,
`"${PMB[@]}" build linux-google-zumapro`, `apk add` the package on the
phone, rebuild the images with `scripts/mkimages-pmos.sh` and flash only
`boot_b`, `vendor_boot_b` and `vendor_kernel_boot_b`.

### 7. Copy the firmware

```sh
KOMODO_WORK=$KOMODO_WORK scripts/install-bt-firmware.sh --dry-run
KOMODO_WORK=$KOMODO_WORK KOMODO_SSH_HOST=<user>@172.16.43.1 \
  KOMODO_SSH_KEY=<your-key> scripts/install-bt-firmware.sh
```

It reads `BCM_200.hcd` from `$KOMODO_WORK/firmware/vendor-firmware/brcm`
(`KOMODO_BT_FW_SRC`), refuses it if its SHA-256 is not the one pinned for
`CP4A.261105.040.A1`, stages it as `BCM.google,zumapro-komodo.hcd` in
`$KOMODO_WORK/build/bt-fw`, copies it to `/lib/firmware/updates/brcm/` (it
asks for your `sudo` password on the phone) and checks the hash there. It
does not touch modules, blacklists or boot images, and it does not read or
set Bluetooth addresses. More in [`../scripts/README.md`](../scripts/README.md).

### 8. First power-up, by hand

Boot the new kernel cold, with the blacklist in place. Before powering the
chip, check that the UART and its serdev child exist:

```sh
uname -r
sudo dmesg | grep -iE '155d0000|ttySAC'          # ttySAC0 at MMIO 0x155d0000
ls /sys/bus/serial/devices/                       # serial0  serial0-0
lsmod | grep -E 'hci_uart|btbcm'                  # nothing yet
ls -l /lib/firmware/updates/brcm/BCM.google,zumapro-komodo.hcd
```

Then:

```sh
sudo modprobe hci_uart
sleep 10
sudo dmesg | grep -iE 'bluetooth|hci0'
```

Lines we got, in order (timestamps removed):

```text
Bluetooth: HCI UART protocol Broadcom registered
hci_uart_bcm serial0-0: supply vbat not found, using dummy regulator
hci_uart_bcm serial0-0: supply vddio not found, using dummy regulator
Bluetooth: hci0: BCM: chip id 200
Bluetooth: hci0: BCM: features 0x0f
Bluetooth: hci0: BCM4390B1
Bluetooth: hci0: BCM (002.002.008) build 0000
Bluetooth: hci0: BCM 'brcm/BCM.google,zumapro-komodo.hcd' Patch
Bluetooth: hci0: BCM: features 0x0f
Bluetooth: hci0: BCM4390B1 P24 G6BB_V27_KM4 BR:1455 … [Baseline: 1474]
Bluetooth: hci0: BCM (002.002.008) build 0474
Bluetooth: hci0: Failed to read codec capabilities (-22)   (seven times)
Bluetooth: MGMT ver 1.23
Bluetooth: RFCOMM ver 1.11
```

The firmware download took about 4 s. Build `0000` is the ROM; `0474` is
the patched firmware running. It worked at the first attempt.

Then BlueZ:

```sh
sudo systemctl start bluetooth
bluetoothctl power on
bluetoothctl show            # Powered: yes; contains the address: do not paste it
bluetoothctl --timeout 12 scan on
```

### 9. Remove the blacklist and reboot

```sh
sudo rm /etc/modprobe.d/komodo-bt.conf
sudo reboot
```

On our unit, after that reboot: Bluetooth came up by itself, about 10 s
into the boot; the earlier pairing was still there; zero failed systemd
units.

### 10. Checks we ran and what we saw

```sh
systemctl --failed
btmgmt info                  # contains the address: do not paste it
bluetoothctl show
bluetoothctl devices         # contains names and addresses: do not paste them
```

- **Controller:** `hci0`, `Powered: yes`, LE roles central and peripheral.
- **Scan:** a 12 s scan saw 16 devices.
- **Pairing:** paired and connected with a phone from Phosh's Bluetooth
  settings; the pairing survived a reboot.
- **Coexistence:** WiFi stayed connected while Bluetooth scanned, paired
  and connected.
- **Boot:** with the blacklist gone, `hci_uart` autoloads and BlueZ powers
  the controller, ~10 s into the boot; zero failed units.

### 11. Warnings in the log

- `Failed to read codec capabilities (-22)`, seven times, right after the
  firmware patch. The kernel asks the controller for its offload codecs and
  the request is rejected. It did not stop pairing or connecting; not
  investigated. It may matter for Bluetooth audio, which cannot be tested
  yet.
- `supply vbat not found` / `supply vddio not found, using dummy regulator`:
  the node describes no supplies, so the driver uses dummy ones; harmless
  here.

### 12. Back out

- **Bluetooth off, kernel kept:** put the blacklist from step 5 back and
  reboot. With `hci_uart` blacklisted the chip stays unpowered.
- **Firmware off the phone:**
  `KOMODO_WORK=… KOMODO_SSH_HOST=… scripts/install-bt-firmware.sh --remove`
  (deletes `/lib/firmware/updates/brcm/BCM.google,zumapro-komodo.hcd` only).
  Without it, `hci0` would come up on the ROM alone (not tried).
- **Previous kernel:** reflash your Milestone 4 `boot_b`, `vendor_boot_b`
  and `vendor_kernel_boot_b` and downgrade the apk on the phone, as in
  [MILESTONE-3.md step 10](MILESTONE-3.md#10-back-out).

### 13. What does not work or was not tried

1. **Bluetooth address:** the controller uses the chip's default address,
   generic and the same on every BCM4390 that nobody configured. This
   unit's real address has not been located. It has to be given one (for
   example with `btmgmt public-addr`, and something that does it at every
   boot); not done.
2. **Bluetooth audio:** impossible to test, the phone has no audio yet.
   The codec warnings above may be related.
3. **Profiles:** HID (keyboards, mice), A2DP, tethering (PAN) and file
   transfer were not tried. Only pairing and connecting with a phone.
4. **Suspend and long idle:** not tried. `hci_bcm` puts the UART into
   runtime suspend after a few seconds idle, using the wake lines; all we
   know is that it kept working through our session.
5. **4 Mbaud:** stock runs the UART at 4 Mbaud; we use 3 Mbaud.
6. **Throughput, range, battery cost:** not measured.
7. **Upstream:** 0014 and 0015 are not sent anywhere and are not meant to
   be as is (AI-assisted, see the top of this document).

### Not verified

- That 0015's 100 ms delay is needed (the first power-up after boot would
  probably work with 30 ms; the difference matters when the chip is power
  cycled quickly).
- Behaviour with `BCM.hcd` instead of `BCM_200.hcd`.
- Firmware of other Android builds (the pins are for `CP4A.261105.040.A1`
  only).
- Any hardware beyond what is listed in [STATUS.md](STATUS.md).

---

## Español

### Antes de empezar

Vale todo lo de [MILESTONE-4.md](MILESTONE-4.md#antes-de-empezar) y el hito 4
debe funcionar ya en tu unidad. **No se reinstala:** `userdata` no se toca;
solo cambian `boot_b`, `vendor_boot_b` y `vendor_kernel_boot_b`. Hace falta
BlueZ en el teléfono (`bluetoothctl`, el servicio `bluetooth` y `btmgmt`,
que en sistemas basados en Alpine va aparte, en `bluez-btmgmt`). **Sin
garantía:** lo hicimos una vez, en una unidad.

### Resumen de pasos

Los comandos, las tablas completas y los hashes están en la sección inglesa.

1. **Entradas:** paquete del kernel `linux-google-zumapro` `pkgrel=4` (mismo
   commit `ffd33b7…`, 15 parches); config con `BT_LE=y`, `BT_RFCOMM=m` y
   `BT_RFCOMM_TTY=y` nuevos (`BT_LE_L2CAP_ECRED=y` viene por defecto con
   `BT_LE`); paquete del dispositivo sin cambios (`pkgrel=3`); firmware de la
   imagen de fábrica `CP4A.261105.040.A1` (`vendor.img`,
   `/vendor/firmware/brcm/BCM_200.hcd`), que no se redistribuye.
2. **Hardware:** la mitad Bluetooth del mismo combo BCM4390; la ROM dice
   `BCM4390B1` (silicio B1, como el WiFi). Va por la USI1 del APM en
   `0x155d0000` (`serial_18` en stock, `ttySAC0` en Linux). `BT_REG_ON` en
   `gpn8-0` tras un biestable con reloj en `gpp24-3` (`brcm,ble-dbo`),
   `BT_DEV_WAKE` en `gpn9-0`, `BT_HOST_WAKE` en `gpa5-6` (flanco de subida,
   pull-down). Sin pinctrl para los pads de la UART: stock no lo describe y
   en `komodo` los pads `gpa3` que usaría el `uart18_bus` de zuma tienen
   otra función.
3. **Parches:** 0014 (DTS) activa `cmu_peric1`, `pinctrl_peric1`,
   `pinctrl_far_alive` con las interrupciones de `gpa5`, `usi_apm1` y
   `uart18`, y añade el nodo `bluetooth` (`brcm,bcm4390-bt`,
   `brcm,bcm4389-bt`) a 3 Mbaud. 0015 añade `brcm,bcm4390-bt` a `hci_bcm`
   con 100 ms de `BT_REG_ON` bajo antes de encender (el valor del HAL de
   fábrica; el 4389 usa 30 ms). `btbcm` no cambia: pide
   `brcm/BCM.google,zumapro-komodo.hcd`. Los mensajes de 0014 y 0015 siguen
   diciendo que no están probados y que se deje `hci_uart` en lista negra:
   se conservan como se compilaron.
4. **Firmware de tu propia imagen de fábrica:** como en el hito 4; el
   fichero es `/firmware/brcm/BCM_200.hcd` dentro de `vendor.img` (con ext4,
   `debugfs -R 'dump /firmware/brcm/BCM_200.hcd BCM_200.hcd' vendor.img`,
   sin root), a `$KOMODO_WORK/firmware/vendor-firmware/brcm/`. Es el que
   carga el HAL de fábrica y su cabecera dice `BCM4390B1`. Hay también un
   `BCM.hcd` que la configuración de fábrica no usa (`--alt`); nunca nos hizo
   falta. Los SHA-256 son de ficheros públicos de la imagen de Google y no
   identifican la unidad.
5. **Lista negra antes del primer arranque del kernel nuevo:**
   `/etc/modprobe.d/komodo-bt.conf` con `blacklist hci_uart`; sin ella, el
   chip se enciende y carga el firmware nada más arrancar.
6. **Kernel sin reinstalar:** igual que en el paso 6 del hito 4.
7. **Copiar el firmware** con `scripts/install-bt-firmware.sh` (primero
   `--dry-run`): comprueba el SHA-256 fijado, lo prepara como
   `BCM.google,zumapro-komodo.hcd` dentro de `KOMODO_WORK`, lo copia a
   `/lib/firmware/updates/brcm/` (pide la contraseña de `sudo` del teléfono)
   y comprueba el hash allí. No toca módulos, listas negras, imágenes ni
   direcciones Bluetooth.
8. **Primer encendido, a mano:** arrancar en frío con la lista negra,
   comprobar `ttySAC0` y `serial0-0`, y `sudo modprobe hci_uart`. Al primer
   intento: `chip id 200`, `BCM4390B1`, ROM `build 0000`, carga del parche en
   unos 4 s y `build 0474`; después siete avisos `Failed to read codec
   capabilities (-22)`. BlueZ lo enciende (`Powered: yes`).
9. **Quitar la lista negra y reiniciar:** el Bluetooth sube solo a los
   ~10 s del arranque, el emparejamiento se conserva y no hay unidades de
   systemd fallidas.
10. **Resultados:** `hci0` encendido, roles LE central y periférico; un
    escaneo de 12 s vio 16 dispositivos; emparejado y conectado con un
    teléfono desde los ajustes de Phosh; el WiFi siguió conectado a la vez.
11. **Avisos en el log:** los siete `Failed to read codec capabilities
    (-22)` (sin investigar; no impiden emparejar ni conectar, quizá importen
    para el audio) y los reguladores ficticios `vbat`/`vddio` (el nodo no describe
    alimentaciones; inofensivo).
12. **Vuelta atrás:** volver a poner la lista negra y reiniciar (el chip no
    se enciende); `install-bt-firmware.sh --remove` borra solo
    `BCM.google,zumapro-komodo.hcd` del teléfono; el kernel anterior,
    reflasheando las tres imágenes del hito 4 y bajando el apk.
13. **Lo que no funciona o no se ha probado:** la dirección Bluetooth es la
    por defecto del chip, genérica e igual en todo BCM4390 sin configurar;
    la real de la unidad no se ha localizado y hay que darle una (por
    ejemplo con `btmgmt public-addr`, en cada arranque), pendiente. Audio por
    Bluetooth imposible de probar (el teléfono aún no tiene audio). Sin
    probar: perfiles concretos (HID, A2DP, compartir conexión, ficheros),
    suspensión y reposo prolongado, 4 Mbaud, rendimiento, alcance y
    consumo. 0014 y 0015 no se han enviado a ningún sitio y no deben
    enviarse tal cual (hechos con asistencia de IA).

### Sin verificar

Que haga falta el retardo de 100 ms de 0015 (el primer encendido tras
arrancar seguramente iría con 30 ms; importa al apagar y encender el chip
seguido); el comportamiento con `BCM.hcd`; el firmware de otros builds de
Android (los hashes fijados son solo de `CP4A.261105.040.A1`); el resto del
hardware ([STATUS.md](STATUS.md)).
