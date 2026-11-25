# Roadmap

Phases are sequential; a phase is "done" only when verified on our unit and
recorded in [JOURNAL.md](JOURNAL.md). No dates are promised.

Las fases son secuenciales; una fase solo está "hecha" cuando se verifica en
nuestra unidad y queda anotada en [JOURNAL.md](JOURNAL.md). Sin fechas
comprometidas.

## Phase 0 — Unlock and backup / Desbloqueo y copia de seguridad

Done on 2026-11-24; the backup was taken in Milestone 1. / Hecha el
2026-11-24; la copia de seguridad se hizo en el hito 1.

- [x] Update stock Android (never downgrade: anti-rollback). Left the Android 16
  Beta build; Android 17 `CP4A.261105.040.A1` sideloaded on **both** slots. See
  [UNLOCK.md](UNLOCK.md).
- [x] Unlock the bootloader (wipes data).
- [x] Disable automatic system updates.
- [x] Record partition layout, AVB/dtbo data and slot state (without unique
  identifiers): [DEVICE.md](DEVICE.md).
- [x] Private backup of the identity/calibration partitions (`efs`,
  `efs_backup`, `modem_userdata`, `persist`, `devinfo`, `mfg_data`; in
  practice everything except `userdata` and `super`): **done in Milestone 1** from the RAM-only Linux (without root these
  partitions cannot be read from Android). / Hecha en el hito 1 desde el Linux
  en RAM.

## Phase 1 — Milestone 1: RAM-only Linux on slot B / Hito 1: Linux solo en RAM en el slot B

**Done on 2026-11-24.** / **Hecho el 2026-11-24.** Procedure / Procedimiento:
[MILESTONE-1.md](MILESTONE-1.md).

Goal: boot Linux from slot B entirely in RAM, **without writing `userdata`**. /
Objetivo: arrancar Linux desde el slot B solo en RAM, **sin escribir
`userdata`**.

- [x] Build the `linux-omarchy-mobile` (now `linux-omamobile`) kernel from PR #276 (depends on PR #273),
  pinned to commit `ffd33b7ddc716eb3568fff9f8d337a4032d109eb`.
- [x] Rescue initramfs derived from Omamobile's (MIT, as declared in that
  repository's `LICENSE` file).
- [x] Kernel cmdline: the plan was DTB `/chosen/bootargs` because ABL
  reportedly ignored the `vendor_boot` cmdline. **Verified false on our unit:**
  the ABL appends it, so the bring-up arguments went in `vendor_cmdline`. /
  Verificado que el ABL **sí** añade la cmdline de `vendor_boot`.
- [x] Build the five slot-B images with AVB hash footers: `boot_b`,
  `init_boot_b`, `vendor_boot_b`, `vendor_kernel_boot_b`, `dtbo_b`.
- [x] Flash only those five; keep stock Android on slot A as fallback.

Success criteria / Criterio de éxito (all required / todos obligatorios):

- [x] USB gadget networking + SSH into the phone.
- [x] More than 180 s up without reset (more than 7 min).
- [x] Storage visible **read-only** (62 partitions, none mounted).
- [x] Private copy of the IMEI/calibration partitions (`efs`, `efs_backup`,
  `modem_userdata`, `persist`, `devinfo`, `mfg_data`) taken from that Linux;
  **never** in this repo. In practice everything except `userdata` and
  `super` (60 partitions copied, hashes compared on both ends). / Copia de las
  particiones de identidad/calibración; en la práctica, todas salvo
  `userdata` y `super`.
- [x] Return to Android on slot A works.

Not achieved in Milestone 1: any display output (black screen). / No logrado
en el hito 1: salida de pantalla (negra).
*Later note: a text console on screen was reached afterwards (2026-11-25),
see Phase 2. / Nota posterior: después se logró consola de texto en pantalla
(2026-11-25), ver fase 2.*

## Phase 2 — Milestone 2: Nura on userdata / Hito 2: Nura en userdata

**Done on 2026-11-25.** / **Hecho el 2026-11-25.** Procedure / Procedimiento:
[MILESTONE-2.md](MILESTONE-2.md).

- [x] Package `device-google-komodo` and the kernel `linux-google-zumapro` for
  pmbootstrap: [`../pmaports/device/testing/`](../pmaports/device/testing/).
- [x] Nura edge (console UI, systemd) built with pmbootstrap 3.12.1, root
  filesystem on `userdata`, booted from slot B to `login:` on screen and SSH
  over USB. Android data lost (expected). / Nura en `userdata`, arrancado
  desde el slot B; datos de Android perdidos (esperado). *Later note: once
  touch worked, Nura was reinstalled with the `buffyboard` UI (2026-11-25). /
  Nota posterior: con el táctil funcionando, Nura se reinstaló con la UI
  `buffyboard` (2026-11-25).*
- [x] Display, text console: **done on 2026-11-25** with the "display A"
  kernel variant: `gs-decon` built in, `simple-framebuffer` on the bootloader
  framebuffer at `0xfac00000`, `gs_decon.stage=1`; `simpledrm` + `fbcon`,
  confirmed by eye. Patches now published in the kernel package. / Pantalla,
  consola de texto: **hecho el 2026-11-25**; parches publicados en el paquete
  del kernel.
- [x] Buttons checked from the installed system: power key seen by logind but
  no action; Power+Vol− does not reach fastboot from Linux (see Phase 2b). /
  Botones comprobados: ver fase 2b.

Not achieved in Milestone 2 / No logrado en el hito 2: slot B is never marked
successful (see Phase 2b). / el slot B nunca se marca como correcto.

## Phase 2b — Make Milestone 2 livable / Hacer usable el hito 2

**Partly done in Milestone 3 (2026-11-25)**, see
[MILESTONE-3.md](MILESTONE-3.md); the retry counter is still the main open
item. / **En parte hecho en el hito 3 (2026-11-25)**; el contador de intentos
sigue siendo lo principal pendiente.

- [ ] Slot-B retry counter: every boot spends 1 of 3 and nothing marks the
  slot successful; at 0 the ABL boots slot A. Today: `fastboot set_active b`
  by hand. Options: mark the slot successful (third-party notes place the
  counter in `devinfo`; layout on `komodo` unverified, risky; do not write `devinfo` / no escribir `devinfo`) or another
  approach. / Contador de intentos del slot B.
  *Milestone 3: a `komodo-bootctl` tool (decode `devinfo`; write only
  behind explicit flags) and a `komodo-boot-success` timer ship in the
  device package, but the tool is source only (not compiled) and the write
  has never been run; the timer is not enabled. Still open. / Hito 3: la
  herramienta va en el paquete solo como fuente, sin compilar, y la
  escritura nunca se ha ejecutado. Sigue abierto.*
- [ ] Measure how much a Linux panic consumes of the slot-B retry counter. /
  Medir cuánto consume un pánico de Linux del contador de intentos.
- [x] Reliable way to the bootloader from Linux: **done in Milestone 3**,
  `reboot bootloader` (patch 0007 `syscon-reboot-mode` + `reboot=warm`)
  reaches fastboot without buttons and without spending an extra retry. /
  Forma fiable de ir al bootloader desde Linux: **hecho en el hito 3**.
- [ ] Buttons: power key handling (poweroff/reboot) and volume keys; no
  verified action under Phosh yet. / Botones: tecla de encendido y volumen;
  sin acción comprobada bajo Phosh.
- [ ] Power off: not tested. / Apagado: sin probar.
- [x] Touchscreen: **done on 2026-11-25** (see Phase 3); Nura reinstalled
  with the `buffyboard` UI, login on the phone by touch. / Táctil: **hecho el
  2026-11-25** (ver fase 3); Nura reinstalado con la UI `buffyboard`, login
  en el teléfono tocando.
- [x] Battery readout (Phase 4): **done in Milestone 3** (fuel gauge and
  charger, read-only). Charging control: Phase 4. / Lectura de batería:
  **hecho en el hito 3**; control de carga: fase 4.
- [x] Display: backlight (minimal `google,km4` driver) and real KMS
  (`gs-decon` stage 2): **done in Milestone 3**. / Pantalla: brillo y KMS
  real, **hecho en el hito 3**.
  - [ ] Still open: 120 Hz, real panel sleep (display off/sleep-in on a KMS
    port), suspend/resume. / Pendiente: 120 Hz, reposo real del panel,
    suspensión.
- [x] Graphical UI: **Phosh, done in Milestone 3** (graphical login by
  touch, GPU-accelerated). / UI gráfica: **Phosh, hecho en el hito 3**.
  - [ ] `buffyboard.service` stays enabled under Phosh and injects phantom
    key presses; disabled by hand. Find what enables it and fix it in the
    packages. / `buffyboard.service` sigue activo bajo Phosh; averiguar qué
    lo habilita y corregirlo en los paquetes.
- [x] WiFi (Phase 5): **done in Milestone 4** (2026-11-25), with the limits
  listed there. / WiFi (fase 5): **hecho en el hito 4**, con sus límites.
- [ ] `systemd-firstboot.service` fails on the first boot of every new
  install (no input console) and leaves that boot `degraded`. / Falla en el
  primer arranque de cada instalación nueva y deja ese arranque `degraded`.
- [ ] Understand the USB enumeration failure (`-71`): seen on the first
  boot in Milestone 2, intermittent on some boots in Milestone 3. / Entender
  el fallo de enumeración USB (`-71`): puntual en el hito 2, intermitente en
  algunos arranques del hito 3.

Trade-off: there is only one `userdata`. Booting stock Android on slot A is
reported by third parties to reformat `userdata` (not verified by us), and then
the Linux root is lost. / Contrapartida: solo hay un `userdata`; según
terceros, si Android stock arranca lo reformatea (no verificado por nosotros) y
se pierde la raíz Linux.

## Phase 3 — Touch and GPU / Táctil y GPU

- [x] Synaptics touchscreen: **done on 2026-11-25.** Synaptics S3908 over SPI
  (TouchComm) on `spi@111d0000`; patch 0004 of `linux-google-zumapro`
  (`pkgrel=1`) removes the `status = "disabled"` that PR #276 left on the
  node by policy; driver `synaptics_tcm` (Omamobile tree, not mainline)
  already built in; no external firmware. Typing and login by touch with
  `buffyboard`. / Táctil Synaptics: **hecho el 2026-11-25** (parche 0004,
  `pkgrel=1`; login tocando con `buffyboard`).
  - [x] Graphical UI by touch: Phosh (Milestone 3). / UI gráfica tocando:
    Phosh (hito 3).
  - [ ] Not tested yet: real multitouch, palm rejection, accuracy/calibration,
    touch across suspend/resume. / Sin probar aún: multitáctil real, rechazo
    de palma, precisión/calibración, suspensión/reanudación.
- [x] Mali-G715 GPU: **done in Milestone 3.** Patch 0011, Panthor with the
  CSF firmware from `linux-firmware-arm`, Mesa 26.3.1 ("Mali-G715 MC7
  (Panfrost)", OpenGL ES 3.1); autoloads since device `pkgrel=3`. / GPU
  Mali-G715: **hecho en el hito 3.**
  - [ ] Still open: a power domain driver for G3D (today it relies on the
    bootloader leaving it on), DVFS above 302 MHz with thermal limits,
    suspend, performance measurements. / Pendiente: driver de power domain
    de G3D, DVFS por encima de 302 MHz con límites térmicos, suspensión,
    medidas de rendimiento.

## Phase 4 — Battery, charging, Type-C / Batería, carga, Type-C

- [x] Fuel gauge and charger (MAX77779) described and read: **done in
  Milestone 3** (patches 0005–0006; percentage and design capacity, charger
  detected). / Fuel gauge y cargador: **hecho en el hito 3** (lectura).
- [ ] Charging that actually charges: today a PC USB port gives 500 mA and
  the battery barely charges; needs USB-PD through the TCPC, a charge
  policy and thermal bands. / Que cargue de verdad: hoy un USB de PC da
  500 mA y casi no carga.
- [ ] Low-battery shutdown (UPower or similar). / Apagado por batería baja.
- [ ] USB Type-C: TCPC as a sink first (patch prepared, not integrated), then
  USB-PD, then role switching. / USB Type-C: TCPC como sumidero (parche
  preparado, sin integrar), luego USB-PD y cambio de rol.

## Phase 5 — WiFi and Bluetooth

- [x] BCM4390 WiFi over PCIe (`14e4:4438`): **done in Milestone 4
  (2026-11-25)**, see [MILESTONE-4.md](MILESTONE-4.md). Patch 0012 brings up
  `pcie_1` (Gen3 x1) and 0013 adds the chip to `brcmfmac` (not upstream, not
  sent anywhere). The firmware is Google's, with no redistribution license we
  know of, so it is not shipped here: each owner extracts it from their own
  factory image (`scripts/install-wifi-firmware.sh`). Scan, WPA connection
  from Phosh, Internet traffic, reconnection at boot. / WiFi BCM4390: **hecho
  en el hito 4**; el firmware no se distribuye aquí.
  - [ ] Measure throughput (e.g. `iperf3` against a host on the same
    network) and latency under load. / Medir el rendimiento real.
  - [ ] WiFi Direct (P2P): `p2p-dev-wlan0` is not created (timeout,
    `err=-5`). / WiFi Direct: no se crea `p2p-dev-wlan0`.
  - [ ] Understand `Set join_pref error (-52)` and the ignored channels
    169/173/177. / Entender el error de `join_pref` y los canales ignorados.
  - [ ] Try 6 GHz, WiFi 7 (EHT/MLO), access point mode, power saving and
    suspend; check the regulatory domain. / Probar 6 GHz, WiFi 7, modo AP,
    ahorro de energía, suspensión y dominio regulatorio.
  - [ ] NVRAM chosen without reading the module's OTP; a stable per-phone
    MAC instead of the template one. / NVRAM elegida sin leer la OTP; MAC
    estable en lugar de la de plantilla.
- [ ] Bluetooth (same BCM4390 combo, on the APM UART): **next**. Describe the
  UART and its pins in the DTS, enable `CONFIG_BT_LE`/`CONFIG_BT_RFCOMM`,
  firmware `.hcd` from the owner's factory image. / Bluetooth (mismo combo
  BCM4390, por la UART del APM): **lo siguiente**.

## Phase 6 — Audio and sensors / Audio y sensores

- [ ] Speakers/amps (cs35l41), haptics (cs40l26), AoC path.
- [ ] Sensors.

## Phase 7 — Modem, cameras, NFC, fingerprint / Módem, cámaras, NFC, huella

- [ ] Modem (calls, SMS, data).
- [ ] Cameras.
- [ ] NFC.
- [ ] Fingerprint reader.
