# Journal / Bitácora

Newest entries at the bottom. Record failures too. Never paste unique device
identifiers (serial, IMEI, MAC) or personal data.

Entradas nuevas al final. Anota también los fallos. Nunca pegues
identificadores únicos (serie, IMEI, MAC) ni datos personales.

---

## 2026-11-24 — Feasibility research and reconnaissance / Investigación de viabilidad y reconocimiento

Device state: bootloader locked, stock Android, nothing flashed.

Findings:

- No official `komodo` port in pmaports/Nura; only gs101 (Pixel 6) in testing
  (as of 2026-11-24). Mainline has no `zumapro` (as of 2026-11-24).
- Best base: Omamobile kernel fork `linux-omarchy-mobile` (mainline 7.3-rc6 +
  Tensor, according to the fork's README). Pixel 9a (`tegu`, same SoC) is well advanced there.
- PR #276 adds the `komodo` board (depends on PR #273). Its author reports
  boot, UFS, root on userdata, USB gadget, display and buttons working;
  Type-C, touch, WLAN and GPU described but disabled. Not reproduced by us.
- Alternative reference: Noxyntious/linux branch `pixel9a`
  (`zumapro-komodo.dts`), not verified on hardware.
- Stock reconnaissance: GKI android14-6.1 with 328 vendor modules, 4K pages,
  A/B + Virtual A/B, `super`, boot header v4, pKVM active. Components: BOE
  NT37290, Synaptics touch, BCM4390, Mali-G715, MAX77779 family, cs35l41,
  cs40l26, AoC.
  *Later note (not part of the original entry): the panel identification is
  not confirmed. "BOE NT37290" comes from the loaded module
  `panel_boe_nt37290`; another source (a third-party bring-up) names it
  `google,gs-km4`. See [STATUS.md](STATUS.md).*
- Key constraint: ABL ignores `vendor_boot` cmdline; use DTB `/chosen/bootargs`
  (reported by third parties; not verified by us).
  *Later note (not part of the original entry): disproved on our unit on
  2026-11-24 (Milestone 1). With bootloader `ripcurrentpro-17.0-16433847` the
  ABL **does** append the `vendor_boot` cmdline. / Nota posterior: refutado en
  nuestra unidad; el ABL **sí** añade la cmdline de `vendor_boot`.*

Decisions:

- Flash only slot B; keep stock on slot A.
- Back up `efs`, `efs_backup`, `persist`, `devinfo`, `modem` privately before
  any change.
  *Later note (not part of the original entry): superseded by the milestone
  plan below; the copy is taken from the RAM-only Linux of Milestone 1, after
  flashing the five slot-B boot partitions but before anything writes to
  `userdata` or to any identity partition. / Nota posterior: superada por el
  plan de hitos de abajo.*
- Independent repository with explicit AI disclosure (Nura's AI policy).

Next: Phase 0 in [ROADMAP.md](ROADMAP.md).

---

## 2026-11-24 — Stock update on both slots / Actualización de stock en ambos slots

Starting state: an old Android Beta program build (Android 16, security patch
2025-08), bootloader locked.

What we did:

- Downloaded the official **full OTA** of stable Android 17, build
  `CP4A.261105.040.A1` (security patch 2026-11-05), from `dl.google.com`.
- SHA-256 of the downloaded files matched the values quoted in the Omamobile
  PR. **Not** cross-checked against the table on Google's own OTA page.
- Installed it with `adb sideload` from recovery **twice**, once per slot, so
  both slots carry the same build and the same bootloader:
  - bootloader `ripcurrentpro-17.0-16433847`
  - baseband `g5400c-260818-261007-B-16536938`
- Why: anti-rollback (never end up with an older bootloader on one slot), and
  according to the Omamobile `komodo` bring-up PRs this is the build on which
  the `komodo` kernel was booted (not verified by us).

*Later note (not part of the original entry): read on each slot. After the
first sideload the phone booted from slot B and `ro.bootloader` read
`ripcurrentpro-17.0-16433847`; after the second it booted from slot A and
`ro.bootloader` read the same value. So "same bootloader on both slots" rests
on a read on each slot (`fastboot getvar version-bootloader` only reports the
current one). / Nota posterior: leído en cada slot; tras el primer sideload
arrancó desde el B con `ro.bootloader` = `ripcurrentpro-17.0-16433847` y tras
el segundo desde el A con el mismo valor.*

Estado inicial: build antiguo del programa Android Beta (Android 16, parche
2025-08), bootloader bloqueado. Se instaló por `adb sideload` desde recovery el
OTA completo oficial de Android 17 estable (`CP4A.261105.040.A1`, parche
2026-11-05) dos veces, una por slot, para igualar build y bootloader en ambos.
Los SHA-256 coincidieron con los del PR de Omamobile; no se cotejaron con la
tabla de la web de Google. Guía: [UNLOCK.md](UNLOCK.md).

---

## 2026-11-24 — Bootloader unlocked / Bootloader desbloqueado

- `fastboot flashing unlock` (wipes the phone / borra el teléfono).
- Resulting state: active slot A, both slots marked successful,
  `verifiedbootstate` orange.
- Automatic system updates disabled: an Android OTA would be written to the
  inactive slot (B), which is the one reserved for Linux.
- Nothing Linux-related flashed yet. Our port still has **not** booted on our
  unit.

Estado: slot activo A, ambos slots "successful", `verifiedbootstate` orange.
Actualizaciones automáticas desactivadas. Nada de Linux flasheado todavía.

---

## 2026-11-24 — Factory image analysis / Análisis de la imagen de fábrica

Analysis of the factory image for `CP4A.261105.040.A1` (on the host, nothing
flashed):

- `boot.img`: header v4.
- Stock `vbmeta` **chains** `boot` (rollback location 2) and `init_boot`
  (rollback location 4); `dtbo`, `vendor_boot` and `vendor_kernel_boot` are
  **hash descriptors**. Conclusion: our own images need an AVB hash footer.
  (Not yet tested on the device.)
- `dtbo`: 60 entries. Entry 34 (the one our unit uses, `dtbo_idx=34`) has
  board id `0x00060806`, rev `0x00010000`.
- `vendor_kernel_boot`: 8 base DTBs: 4 `zuma`, 4 `zumapro` (product_id
  `0x9875`) with `/soc_compatible` nodes A0/A1, FOPLP and IPOP.
- Partition sizes: `boot`, `vendor_boot`, `vendor_kernel_boot` 64 MiB;
  `init_boot` 8 MiB; `dtbo` 16 MiB; `userdata` ~228 GiB.

Resumen: header v4; las imágenes propias necesitan pie AVB (hash footer); dtbo
con 60 entradas (la nuestra es la 34); 8 DTB base en `vendor_kernel_boot`.
Detalle en [DEVICE.md](DEVICE.md).

---

## 2026-11-24 — Milestone plan / Plan de hitos

Agreed plan (details in [ROADMAP.md](ROADMAP.md)):

- **Milestone 1:** RAM-only Linux boot from slot B. Five images (`boot_b`,
  `init_boot_b`, `vendor_boot_b`, `vendor_kernel_boot_b`, `dtbo_b`), kernel from
  PR #276 of `linux-omarchy-mobile` pinned to a specific commit, rescue
  initramfs derived from Omamobile's (MIT, as declared in that repository's
  `LICENSE` file). No writes to `userdata`.
  Success: USB gadget + SSH, >180 s without reset, storage read-only, private
  copy of the IMEI/calibration partitions taken from that Linux (they cannot be
  read from Android without root), and return to Android on slot A.
- **Milestone 2:** Nura via pmbootstrap with root on `userdata`. Trade-off:
  there is only one `userdata`; booting stock Android is reported by third
  parties to reformat `userdata` (not verified by us), and then the Linux root
  is lost.
- `fastboot boot` is reportedly not viable on `komodo` (third-party report, not
  verified by us).
- Never flashed: `bootloader`, `radio`, `vbmeta`, `devinfo`, `efs`, `persist`,
  or anything on slot A. Never `flash-all.sh`, never `-w`.
- The private backup moves from Phase 0 into Milestone 1.

Plan acordado: hito 1 = Linux solo en RAM desde el slot B sin tocar `userdata`;
hito 2 = Nura con raíz en `userdata` (según terceros, si Android stock arranca
lo reformatea; no verificado por nosotros).
La copia de seguridad privada pasa a hacerse dentro del hito 1.

---

## 2026-11-24 — Milestone 1 passed / Hito 1 superado

Linux booted from slot B, RAM-only, on our unit. Procedure:
[MILESTONE-1.md](MILESTONE-1.md).

Built:

- Kernel: Omamobile fork `linux-omarchy-mobile`, PR #276 (fork `oscarluke`,
  branch `omamobile-komodo-m1`), commit
  `ffd33b7ddc716eb3568fff9f8d337a4032d109eb`; `defconfig` + `omamobile.config`;
  Android clang r596125, `LLVM=1`. `uname -r` = `7.3.0-rc6-omamobile-push1`.
- Initramfs: Alpine minirootfs 3.24.2 aarch64 + dropbear, with Omamobile's
  `/init` (MIT) in `ram-rescue` mode and **no** UFS write list. Audited before
  use: in that mode it does not write to block devices, does not mount
  partitions and does not mark the slot as successful.
- Five images, flashed **only on slot B**: `boot_b` (header v4, kernel
  `Image.lz4`, no ramdisk), `init_boot_b` (empty ramdisk, `os_version` 17.0.0,
  patch 2026-11), `vendor_boot_b` (v4, page size 0x800, empty fragment),
  `vendor_kernel_boot_b` (v4, DTB `zumapro-komodo` + 1.5 MiB lz4 initramfs),
  `dtbo_b` (one entry, id 0x60806 rev 0x10000). All with an AVB hash footer:
  `SHA256_RSA4096` with AOSP's public test key (`testkey_rsa4096`), rollback
  index 1793836800, props `os_version` 17 and `security_patch` 2026-11-05,
  size = partition size. `vbmeta_b` left stock. The unlocked bootloader
  **booted them** (verified).

Flash and slots:

- `fastboot flash` of any `_b` partition set `slot-successful:b=no`.
- `fastboot set_active b` gave 3 retries (`slot-retry-count:b: 3`). Linux never
  marks the slot as successful.

Result:

- After `set_active b` and reboot, the USB gadget (`1d6b:0104`, NCM + ACM)
  enumerated on the PC after ~24 s. Serial console over ACM and SSH over USB
  both worked.
- `/proc/bootconfig`: `slot_suffix` `"_b"`. 62 UFS partitions detected, all 62
  read-only, none mounted. `MemTotal` ~15.5 GiB. Both s3c2410 watchdogs report
  "watchdog inactive, reset disabled". System clock advances at a normal rate.
- dmesg clean except warnings about undescribed UFS regulators and
  `cpufreq-dt: deferred probe pending`.
- Stable for several minutes (more than 7 min uptime) until we forced it off.
- **Display: black for the whole Linux boot.** The device tree has no
  `simple-framebuffer`, only a reserved-memory `framebuffer@fac00000`. This
  qualifies the third-party "display reported": on our unit, with this tree,
  there is **no** display output.

Findings:

- The ABL **does** append the `vendor_boot` cmdline on `komodo` with this
  bootloader: the final cmdline is the DTB bootargs, followed by our
  `vendor_cmdline`, followed by parameters added by the bootloader. This
  corrects the earlier "ABL ignores the vendor_boot cmdline (reported by third
  parties)".
- The bootloader-added parameters include
  `exynos_drm.panel_name=google-km4.…` (the bootloader identifies this unit's
  panel as `google-km4`; `panel_boe_nt37290` was the module loaded by Android)
  and `console=null`.
- **Power + Volume Down** reaches fastboot on `komodo` (verified).

Backup:

- From that Linux, over SSH: 60 partitions (all except `userdata` and
  `super`), ~1.5 GiB, each with its SHA-256 compared between phone and copy.
  Stored privately, outside this repository.
- Also verified: `boot_a` still identical to the stock factory image, `boot_b`
  identical to our image.

Return to Android:

- Holding Power + Volume Down got the phone to fastboot. By then the
  bootloader had already gone back to `current-slot=a` by itself, with
  `slot-retry-count:b=0` (the forced reboots used up the retries). We ran
  `set_active a` anyway; Android booted on A with its data intact (USB
  debugging still authorized, automatic updates still disabled).

Problems / incidents:

- Host network clash: the gadget uses `172.16.42.1/24`, the same subnet other
  postmarketOS phones use by default; with another one connected to the same
  PC the routes clashed. Fixed by adding a second IP in another subnet to the
  phone's `usb0` (RAM only).
- No display output at all (see above).

Not verified yet: how much a Linux panic consumes of the retry counter;
framebuffer; all hardware beyond UFS (read-only), USB gadget, RAM and CPU;
buttons under Linux.

Resumen: hito 1 superado. Kernel `7.3.0-rc6-omamobile-push1` (PR #276, commit
`ffd33b7`) arrancado desde el slot B solo en RAM, con cinco imágenes con pie
AVB de la clave de prueba de AOSP y `vbmeta_b` stock; el bootloader
desbloqueado las arrancó. Gadget USB a los ~24 s, consola serie y SSH; 62
particiones UFS en solo lectura y ninguna montada; estable más de 7 minutos.
Pantalla negra (el device tree no tiene `simple-framebuffer`). Hallazgos: el
ABL **sí** añade la cmdline de `vendor_boot`; el bootloader nombra el panel
`google-km4`; Encendido + Volumen − lleva a fastboot. Copia privada de 60
particiones con SHA-256 en ambos extremos, fuera del repo. El bootloader volvió
solo al slot A tras agotar los intentos de B; Android arrancó con sus datos
intactos. Incidencia: choque de subred `172.16.42.0/24` con otros teléfonos
postmarketOS en el mismo PC, resuelto con una segunda IP en el `usb0` del
teléfono.

---

## 2026-11-24 — Display variant A, first test (no visual confirmation) / Variante de pantalla A, primera prueba (sin confirmación visual)

Kernel variant "display A", tested RAM-only from slot B. Changes compared with
Milestone 1:

- `gs-decon` driver built into the kernel (`=y`) instead of as a module.
- A `simple-framebuffer` node under `/chosen` in the device tree, pointing at
  the framebuffer the bootloader leaves on: address `0xfac00000`, 1344x2992,
  stride 5376, format `a8r8g8b8`.
- Extra cmdline parameters: `gs_decon.stage=1`, `fbcon=font:TER16x32`,
  `omamobile.debug`.

Why stage 1: the panel is a command-mode DSI panel, and the bootloader leaves
the frame trigger masked, so nothing new reaches the panel. Stage 1 of
`gs-decon` unmasks it and enables the frame start/done interrupts.

Result that day, read over SSH:

- `/proc/fb`: `0 simpledrmdrmfb`.
- `fbcon` at 84x93 characters.
- Frames at ~60 Hz.
- The framebuffer contents, read back over SSH, contained the console.
- **No visual confirmation:** nobody was in front of the phone.

Also built but **not tested**: variant B (`gs_decon.stage=2 gs_decon.fbdev=1`,
KMS flip-only, without `simple-framebuffer`).

Resumen: variante de kernel "display A" probada solo en RAM desde el slot B:
`gs-decon` integrado (`=y`), nodo `simple-framebuffer` en `/chosen` sobre el
framebuffer que deja el bootloader (`0xfac00000`, 1344x2992, stride 5376,
`a8r8g8b8`) y `gs_decon.stage=1`, `fbcon=font:TER16x32`, `omamobile.debug` en
la cmdline. El panel es DSI en modo comando y el bootloader deja el trigger de
frame enmascarado; el stage 1 lo desenmascara y activa las interrupciones de
frame start/done. Por SSH: `/proc/fb` = `0 simpledrmdrmfb`, fbcon de 84x93
caracteres, frames a ~60 Hz y la consola presente en el contenido del
framebuffer. Sin confirmación visual (nadie delante del teléfono). La variante
B (`gs_decon.stage=2 gs_decon.fbdev=1`, KMS solo con flip, sin
`simple-framebuffer`) está construida pero sin probar.

---

## 2026-11-25 — Display confirmed: text console on screen / Pantalla confirmada: consola de texto

- The same set of "display A" images was flashed again on slot B and booted;
  the USB gadget appeared after ~26 s.
- A test message was written to `/dev/tty0`.
- The owner confirmed **by eye** that the screen shows the Linux console.

Display status on our unit: **works as a text console** (`simpledrm` on the
bootloader's framebuffer). Limitations:

- No GPU and no acceleration.
- No real modesetting: there is no `km4` panel driver in the tree.
- No backlight device: brightness is whatever the bootloader left.
- No screen off/on.
- Touchscreen still untested.

Device state after this entry: slot B carries the five "display A" images (no
longer the Milestone 1 ones); `vbmeta_b` stock; slot A untouched with Android
17 `CP4A.261105.040.A1`. Still RAM-only; Nura not installed.

The display patches are not published in this repository yet; they will be
published later.

Resumen: se reflashearon en el slot B las mismas imágenes "display A", el
teléfono arrancó (gadget USB visible a los ~26 s), se escribió un mensaje de
prueba en `/dev/tty0` y el dueño confirmó **a ojo** que la pantalla muestra la
consola de Linux. Pantalla: **funciona como consola de texto** (`simpledrm`
sobre el framebuffer del bootloader). Limitaciones: sin GPU ni aceleración, sin
modesetting real (no hay driver del panel `km4` en el árbol), sin dispositivo
de backlight (el brillo es el que deja el bootloader), sin apagar/encender la
pantalla; táctil sin probar. El slot B lleva ahora las cinco imágenes de
"display A" en vez de las del hito 1; `vbmeta_b` stock; slot A intacto con
Android 17 `CP4A.261105.040.A1`. Sigue siendo solo RAM; Nura no instalado. Los
parches de pantalla aún no están publicados en el repo; se publicarán más
adelante.
