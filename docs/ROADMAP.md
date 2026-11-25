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
  desde el slot B; datos de Android perdidos (esperado).
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

**Next.** / **Siguiente.**

- [ ] Slot-B retry counter: every boot spends 1 of 3 and nothing marks the
  slot successful; at 0 the ABL boots slot A. Today: `fastboot set_active b`
  by hand. Options: mark the slot successful (third-party notes place the
  counter in `devinfo`; layout on `komodo` unverified, risky; do not write `devinfo` / no escribir `devinfo`) or another
  approach. / Contador de intentos del slot B.
- [ ] Measure how much a Linux panic consumes of the slot-B retry counter. /
  Medir cuánto consume un pánico de Linux del contador de intentos.
- [ ] Buttons: power key handling (poweroff/reboot) and a reliable way to the
  bootloader from Linux. / Botones: tecla de encendido y forma fiable de ir al
  bootloader desde Linux.
- [ ] Touchscreen (Phase 3), battery and charging (Phase 4), WiFi (Phase 5):
  next in priority. / Táctil, batería/carga y WiFi: lo siguiente.
- [ ] Display, the rest: panel driver for `google-km4` and real KMS
  modesetting (variant B, `gs_decon.stage=2 gs_decon.fbdev=1`, built but
  untested), backlight, screen off/on. / Pantalla, lo que falta: driver de
  panel/KMS, backlight, apagar/encender. GPU: Phase 3. / GPU: fase 3.
- [ ] Understand the one-off USB enumeration failure (`-71`) on the first
  boot. / Entender el fallo puntual de enumeración USB (`-71`) del primer
  arranque.

Trade-off: there is only one `userdata`. Booting stock Android on slot A is
reported by third parties to reformat `userdata` (not verified by us), and then
the Linux root is lost. / Contrapartida: solo hay un `userdata`; según
terceros, si Android stock arranca lo reformatea (no verificado por nosotros) y
se pierde la raíz Linux.

## Phase 3 — Touch and GPU / Táctil y GPU

- [ ] Synaptics touchscreen.
- [ ] Mali-G715 GPU (Panthor/Mesa status: unverified).

## Phase 4 — Battery, charging, Type-C / Batería, carga, Type-C

- [ ] Fuel gauge and charger (MAX77779 family).
- [ ] USB Type-C role switching.

## Phase 5 — WiFi and Bluetooth

- [ ] BCM4390 WiFi (firmware licensing: unverified).
- [ ] Bluetooth.

## Phase 6 — Audio and sensors / Audio y sensores

- [ ] Speakers/amps (cs35l41), haptics (cs40l26), AoC path.
- [ ] Sensors.

## Phase 7 — Modem, cameras, NFC, fingerprint / Módem, cámaras, NFC, huella

- [ ] Modem (calls, SMS, data).
- [ ] Cameras.
- [ ] NFC.
- [ ] Fingerprint reader.
