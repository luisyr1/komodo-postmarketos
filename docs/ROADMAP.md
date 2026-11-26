# Roadmap

Phases are sequential; a phase is "done" only when verified on our unit and
recorded in [JOURNAL.md](JOURNAL.md). No dates are promised.

Las fases son secuenciales; una fase solo está "hecha" cuando se verifica en
nuestra unidad y queda anotada en [JOURNAL.md](JOURNAL.md). Sin fechas
comprometidas.

## Next, in this order / Lo siguiente, en este orden

As of 2026-11-26, after Milestone 6 (first audio, experimental) and the
slot-B retry counter fix. / A fecha 2026-11-26, tras el hito 6 (primer
audio, experimental) y el arreglo del contador del slot B.

1. **Audio, in this order** (Phase 6). / **Audio, en este orden** (fase 6).
   1. Build and boot `pkgrel=7`: **done on 2026-11-26** (built, installed
      and booted; a default `aplay` plays to the end on EP6). / Compilar y
      arrancar el `pkgrel=7`: **hecho el 2026-11-26** (compilado, instalado
      y arrancado; un `aplay` por defecto llega al final en EP6).
   2. Connect PipeWire to the card with a WirePlumber rule that puts a
      volume ceiling on it, and only then lift the udev rule that hides the
      card. / Conectar PipeWire a la tarjeta con una regla de WirePlumber
      con techo de volumen, y solo entonces quitar la regla udev que la
      oculta.
   3. **Speaker-protection firmware and calibration**: Cirrus' protection
      firmware on both amplifiers, the unit's own factory calibration read
      read-only, health monitoring and ceilings measured for `komodo`.
      **Required before any daily-use volume.** / **Firmware de protección
      y calibración**: el firmware de protección de Cirrus en los dos
      amplificadores, la calibración de fábrica de la unidad leída en solo
      lectura, vigilancia de su estado y techos medidos para `komodo`.
      **Imprescindible antes de cualquier volumen de uso diario.**
   4. Top speaker (also the earpiece), then stereo. / Altavoz superior
      (también auricular) y después estéreo.
   5. The other two microphones, and `dmic_power_list` in the DT. / Los
      otros dos micrófonos, y `dmic_power_list` en el DT.
   6. Bluetooth audio: A2DP first, then headsets (HFP). / Audio por
      Bluetooth: primero A2DP, luego manos libres (HFP).
2. **A Bluetooth address of our own** (Phase 5): today the controller uses
   the chip's generic default address. / **Dirección Bluetooth propia**
   (fase 5): hoy el controlador usa la dirección por defecto, genérica, del
   chip.
3. **Cameras** (Phase 7): feasibility studied, plan below; no code yet. /
   **Cámaras** (fase 7): viabilidad estudiada, plan abajo; aún sin código.
4. **Easy unlock** (Phase 7): fingerprint, face and Bluetooth proximity, all
   three in the long run; face unlock depends on the front camera. The
   fingerprint reader is Qualcomm's ultrasonic sensor, driven from the
   secure world; the realistic path is the factory HAL talking to Trusty
   (as Omamobile does on the Pixel 9a), and Trusty already answers in our
   kernel since Milestone 6. There is an irreversible step (RPMB) on that
   path, not taken. Not started. / **Desbloqueo cómodo** (fase 7): huella,
   cara y proximidad por Bluetooth, las tres a la larga; la cara depende de
   la cámara frontal. El lector de huella es el ultrasónico de Qualcomm,
   manejado desde el mundo seguro; la vía realista es el HAL de fábrica
   hablando con Trusty (como hace Omamobile en el Pixel 9a), y Trusty ya
   responde en nuestro kernel desde el hito 6. En ese camino hay un paso
   irreversible (RPMB) que no se ha dado. Sin empezar.
5. **NPU** (Phase 8): the Tensor G4 has a machine-learning accelerator
   (Google's TPU). Find out whether it can be used from mainline Linux at
   all (driver, firmware, a userspace runtime), and how fast it is, with
   local speech transcription as the first use in mind. Feasibility not
   studied yet; nothing run on the phone. / **NPU** (fase 8): el Tensor G4
   lleva un acelerador de aprendizaje automático (la TPU de Google).
   Averiguar si se puede usar desde Linux mainline (driver, firmware, un
   runtime en espacio de usuario) y qué potencia da, pensando primero en
   transcripción de voz en local. Viabilidad sin estudiar; nada ejecutado
   en el teléfono.

The open items of Phases 2b–5 (buttons, charging, WiFi throughput…) stay
open alongside. / Los pendientes de las fases 2b–5 (botones, carga,
rendimiento del WiFi…) siguen abiertos en paralelo.

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
*Later note: slot B was marked successful on 2026-11-26, see Phase 2b. /
Nota posterior: el slot B se marcó como correcto el 2026-11-26, ver fase 2b.*

## Phase 2b — Make Milestone 2 livable / Hacer usable el hito 2

**Partly done in Milestone 3 (2026-11-25)**, see
[MILESTONE-3.md](MILESTONE-3.md); the retry counter was fixed on our unit on
2026-11-26. / **En parte hecho en el hito 3 (2026-11-25)**; el contador de
intentos quedó resuelto en nuestra unidad el 2026-11-26.

- [x] Slot-B retry counter: **done on our unit on 2026-11-26**, see
  [SLOT-B.md](SLOT-B.md). `komodo-boot-success --write` set the
  `successful` bit of slot B in `devinfo` (layout 3.19; one byte, `0x35`:
  `14 -> 16`, written and verified). Three Linux → fastboot rounds without
  `set_active`: `slot-successful:b` = yes and `slot-retry-count:b` = 2 every
  time, so the counter no longer drops. Consequence: the ABL no longer falls
  back to slot A by itself (deduced: no failed boot has been tried with B marked); a broken slot B is repaired from fastboot with
  the buttons. / Contador de intentos del slot B: **hecho en nuestra unidad
  el 2026-11-26**: un byte de `devinfo` (`0x35`: `14 -> 16`), escrito y
  verificado; en tres rondas Linux → fastboot sin `set_active`,
  `slot-successful:b` = yes y `slot-retry-count:b` = 2 las tres veces. El
  ABL ya no vuelve solo al slot A (deducción: no se ha provocado un fallo con B marcado); un slot B roto se repara desde fastboot
  con los botones.
  *Milestone 3 shipped the `komodo-bootctl` tool as source only; device
  `pkgrel=4` builds it into the package (built, installed and checked on our
  unit on 2026-11-26).
  The timer stays installed but not enabled: each owner decides. / En el
  hito 3 la herramienta iba solo como fuente; el dispositivo `pkgrel=4` la
  compila en el paquete (compilado, instalado y comprobado en nuestra unidad
  el 2026-11-26). El temporizador
  sigue instalado sin activar: lo decide cada dueño.*
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
- [x] Bluetooth (Phase 5): **done in Milestone 5** (2026-11-25), with the
  limits listed there. / Bluetooth (fase 5): **hecho en el hito 5**, con sus
  límites.
- [ ] Audio (Phase 6): **first sound in Milestone 6** (2026-11-25), still
  experimental and not usable from the desktop. / Audio (fase 6): **primer
  sonido en el hito 6**, aún experimental y sin uso desde el escritorio.
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
- [x] Bluetooth (same BCM4390 combo, on the APM UART): **done in
  Milestone 5 (2026-11-25)**, see [MILESTONE-5.md](MILESTONE-5.md). Patch
  0014 describes the UART, the power latch and the wake lines in the DTS;
  0015 adds the BCM4390 to `hci_bcm` with a 100 ms power-on delay (neither
  upstream nor sent anywhere); config with `BT_LE`, `BT_RFCOMM`,
  `BT_RFCOMM_TTY`. The `.hcd` firmware is Google's and is not shipped here:
  each owner extracts it from their own factory image
  (`scripts/install-bt-firmware.sh`). Scan, pairing and connection with a
  phone from Phosh, autoload at boot, WiFi working at the same time. /
  Bluetooth: **hecho en el hito 5**; el firmware no se distribuye aquí.
  - [ ] A proper Bluetooth address: the controller uses the chip's default
    one, the same on every unconfigured BCM4390. Find where the unit's own
    address comes from (where stock Android gets it has not been found)
    or set a stable one at every boot (`btmgmt public-addr` or similar). /
    Dirección propia: hoy usa la de por defecto del chip; localizar la de la
    unidad o fijar una estable en cada arranque.
  - [ ] Understand the seven `Failed to read codec capabilities (-22)`. /
    Entender los avisos de capacidades de códec.
  - [ ] Try profiles: HID (keyboard, mouse), A2DP (see Phase 6), PAN
    tethering, file transfer. / Probar perfiles: HID, A2DP (ver fase 6),
    compartir conexión, ficheros.
  - [ ] Suspend and long idle (runtime PM over the wake lines), and the
    stock 4 Mbaud link speed. / Suspensión y reposo prolongado, y los
    4 Mbaud de fábrica.

## Phase 6 — Audio and sensors / Audio y sensores

**First sound in Milestone 6 (2026-11-25), experimental**, see
[MILESTONE-6.md](MILESTONE-6.md). / **Primer sonido en el hito 6
(2026-11-25), experimental.**

> The amplifiers run without Cirrus' protection firmware and without the
> factory calibration: a higher volume can damage a speaker irreversibly.
> No level above the bring-up minimum until the protection item below is
> done. / Los amplificadores van sin firmware de protección ni calibración:
> un volumen mayor puede dañar un altavoz de forma irreversible. Ningún
> nivel por encima del mínimo de puesta en marcha hasta cerrar el punto de
> protección de abajo.

- [x] AoC: Trusty, the GSA and the AoC start (firmware `16099865-polygon`,
  94 services), patches 0016–0021. / AoC: arrancan Trusty, la GSA y el AoC.
- [x] Amplifiers identified (two CS35L41 rev B2 on `spi19`; 0017 is
  Omamobile's PR #204). / Amplificadores identificados.
- [x] First tone on the bottom speaker at the bring-up minimum (heard). /
  Primer tono por el altavoz inferior al mínimo (se oyó).
- [x] Microphone 0 captures (closed loop with the speaker). / El micrófono 0
  graba (bucle cerrado con el altavoz).
- [x] Build and boot `pkgrel=7` (EP6 fix 0022, Omamobile's PR #203, plus
  0023): **done on 2026-11-26**; a default `aplay` plays to the end on EP6.
  / Compilar y arrancar el `pkgrel=7`: **hecho el 2026-11-26**; un `aplay`
  por defecto llega al final en EP6.
- [ ] PipeWire/WirePlumber with a volume ceiling; desktop sound. /
  PipeWire/WirePlumber con techo de volumen; sonido en el escritorio.
- [ ] Speaker-protection firmware and factory calibration (prerequisite for
  daily-use levels). / Firmware de protección y calibración de fábrica
  (requisito para niveles de uso diario).
- [ ] Top speaker and earpiece; stereo. / Altavoz superior y auricular;
  estéreo.
- [ ] Microphones 1 and 2; `dmic_power_list` in the DT. / Micrófonos 1 y 2;
  `dmic_power_list` en el DT.
- [ ] Bluetooth audio (A2DP, HFP) and calls (needs the modem). / Audio por
  Bluetooth (A2DP, HFP) y llamadas (necesita el módem).
- [ ] AoC recovery: the ACPM reset callback is not registered, so a crashed
  AoC needs a reboot. / Recuperación del AoC: sin el callback de reset, un
  AoC caído pide reiniciar.
- [ ] Haptics (cs40l26). / Vibración.
- [ ] Sensors (they also live on the AoC). / Sensores (también están en el
  AoC).

## Phase 7 — Modem, cameras, NFC, fingerprint / Módem, cámaras, NFC, huella

- [ ] Modem (calls, SMS, data).
- [ ] Cameras: feasibility studied on 2026-11-25 (desk research on the
  factory image and on the Pixel 9a's work; nothing run on the phone). /
  Cámaras: viabilidad estudiada el 2026-11-25 (estudio de la imagen de
  fábrica y del trabajo del Pixel 9a; nada ejecutado en el teléfono).
  - Sensors, from the stock camera HAL's model IDs, not yet read on the
    phone: front **Sony IMX858**; main **Samsung ISOCELL GN-series, 50 MP**
    (exact model not settled). / Sensores, según los ID de modelo del HAL
    de fábrica y sin leer aún en el teléfono: frontal **Sony IMX858**;
    principal **Samsung ISOCELL serie GN, 50 MP**.
  - Why it looks feasible in **weeks** rather than months: the Pixel 9a
    (`tegu`), with the same SoC, already gets images in Omamobile through
    the Tensor CSI-2 receiver driver and libcamera's software ISP, and
    `komodo`'s camera wiring is close to `tegu`'s. A rough guess: a few
    weeks for the front camera, longer for the main one. / Por qué parece
    viable en **semanas**: el Pixel 9a (mismo SoC) ya da imagen en
    Omamobile con el receptor CSI-2 de Tensor y el soft-ISP de libcamera, y
    el cableado de `komodo` se parece mucho; estimación gruesa: unas
    semanas la frontal, más la principal.
  - What is missing: Omamobile's `zumapro` camera changes are still open
    pull requests, not merged and not in our tree; there are no drivers yet
    for these two sensors; and the sensor and PHY register tables have to
    be extracted from each owner's own phone (its camera HAL), since they
    cannot be redistributed. / Falta: los cambios de cámara de `zumapro` en
    Omamobile siguen en PR sin fusionar y no están en nuestro árbol; no hay
    drivers para estos dos sensores; y las tablas de registros del sensor y
    de la PHY hay que sacarlas del propio teléfono de cada dueño, porque no
    se pueden redistribuir.
  - Expected quality: **far below stock**. libcamera's software ISP, no
    Google ISP, no HDR+ or computational photography. / Calidad esperada:
    **muy inferior a la de stock**: soft-ISP de libcamera, sin el ISP de
    Google ni su fotografía computacional.
  - **Physical risk.** Powering the cameras means programming camera power
    regulators, one of which can output far more than the sensors accept;
    `komodo`'s voltages also differ from `tegu`'s, so a Pixel 9a device
    tree must not be copied. A wrong value can damage the hardware. No
    power-up procedure is published here until it has been checked on our
    unit. / **Riesgo físico.** Encender las cámaras implica programar
    reguladores de alimentación, uno de ellos capaz de dar mucha más
    tensión de la que aguantan los sensores, y las tensiones de `komodo` no
    son las del Pixel 9a: no se debe copiar su device tree. Un valor
    erróneo puede dañar el hardware. No se publica ningún procedimiento de
    encendido hasta comprobarlo en nuestra unidad.
  - Plan: bring in the `zumapro` camera support once it is merged in
    Omamobile, first read the front sensor's chip ID only, then raw capture,
    then libcamera; front camera first, main camera after. / Plan: traer el
    soporte de cámara de `zumapro` cuando entre en Omamobile, leer primero
    solo el chip ID del sensor frontal, luego captura en bruto y después
    libcamera; primero la frontal, luego la principal.
- [ ] NFC.
- [ ] Fingerprint reader (part of easy unlock; Qualcomm ultrasonic, secure
  world, factory HAL over Trusty; an irreversible RPMB step not taken; see
  "Next" above). / Lector de huella (parte del desbloqueo cómodo; ver
  "Lo siguiente" arriba).

## Phase 8 — NPU / Acelerador de aprendizaje automático

- [ ] Feasibility study of the Tensor G4's machine-learning accelerator
  (Google's TPU) under mainline Linux: driver, firmware, userspace runtime,
  and measured throughput. First use in mind: local speech transcription.
  Not started. / Estudio de viabilidad del acelerador de aprendizaje
  automático del Tensor G4 (la TPU de Google) bajo Linux mainline: driver,
  firmware, runtime en espacio de usuario y rendimiento medido. Primer uso
  previsto: transcripción de voz en local. Sin empezar.
