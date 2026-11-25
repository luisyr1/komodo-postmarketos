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

---

## 2026-11-25 — Milestone 2: Nura on userdata / Hito 2: Nura en userdata

Procedure: [MILESTONE-2.md](MILESTONE-2.md). Packages published in
[`../pmaports/device/testing/`](../pmaports/device/testing/), images script
[`../scripts/mkimages-pmos.sh`](../scripts/mkimages-pmos.sh).

Build:

- pmbootstrap 3.12.1 with a separate configuration file, work directory and
  pmaports copy; channel edge, UI console, systemd.
- A real `pmbootstrap kconfig check` of `linux-google-zumapro` passed.
- Kernel built with Alpine's clang in ~21 min (16 threads); `uname -r` =
  `7.3.0-rc6-zumapro`.
- The upstream kernel repository has been renamed on GitHub to
  `derekross/linux-omamobile` (the old `linux-omarchy-mobile` URL redirects),
  and the folder inside the tarball is `linux-omamobile-<commit>`; the
  APKBUILD's `builddir` was corrected. The tarball of the pinned commit
  `ffd33b7ddc716eb3568fff9f8d337a4032d109eb` is identical, file by file, to
  the tree tested in Milestone 1.

Rehearsal without `userdata` (non-destructive):

- Only the five `_b` images flashed, with Nura's initramfs (15 MB zstd,
  recompressed to lz4 legacy); `userdata` not touched.
- The ABL accepted them; USB gadget after ~28 s; `ping 172.16.43.1`
  answered.
- The initramfs dropped to its debug shell because it found no root, as
  expected.
- Android's `userdata` stayed intact: Android booted normally afterwards.

Install:

- `userdata` flashed from the bootloader with the sparse image (834 MB;
  fastboot split it into 4 chunks, ~23 s), then booted.
- Nura edge reaches `login:` on the screen (simpledrm console, display variant
  A, parameters in the DTB bootargs).
- Over SSH on USB NCM (`172.16.43.1`): system `running`, 0 failed units, ext4
  root on a loop device over `userdata` with 4096-byte sectors, resized to
  221.6 GiB, 15.1 GiB of RAM, 8 CPUs, slot `_b`, UFS read-only guard
  `--check` = 0.
- Android data lost (expected). Slot A, bootloader, radio and `vbmeta` not
  touched.

Problems and limits:

1. Slot B retry counter: every boot spends 1 of 3 and nothing marks the slot
   successful; when they run out the ABL boots slot A. `fastboot set_active b`
   is needed beforehand. Unresolved.
2. On Nura's first boot the PC did not enumerate the USB device (errors
   `-71`). It did not happen again on later boots. Cause unknown.
3. Several later "USB drops" turned out to be on the PC side: the host's
   static IP was lost on every re-enumeration. Fixed with a NetworkManager
   profile that autoconnects by the MAC `02:6b:6f:6d:6f:01`. The kernel-module
   hypothesis and the UDC-rebind hypothesis were tested live and ruled out.
4. Buttons: logind logs "Power key pressed short", but there is no poweroff or
   reboot. From Linux, Power+Vol− does not reach fastboot; we reached it with a
   button-forced reboot and then holding Vol− (the exact combination was not
   written down).
5. No touch input: typing at the login is impossible; access only over SSH or
   the debug shell (initramfs telnet with `pmos.debug-shell`).
6. No `/sys/class/power_supply`: battery and charging unsupported.
7. With `pmos.debug-shell`, the debug shell on `ttyGS0` comes out garbled (two
   readers); telnet works.
8. Only two modules load by modalias, `clk-acpm` and `gs101_acpm_tmu`;
   cpufreq (schedutil) works with them.

Device state after this entry: Nura on `userdata`, booting from slot B;
`vendor_boot_b` temporarily carries `pmos.debug-shell`; `vbmeta_b` stock;
slot A untouched (Android 17 `CP4A.261105.040.A1`, without its data).

The display patches, the two packages and the image script are now published
in this repository (the patches' `Date:` lines normalised to UTC, checksums
updated).

Resumen: hito 2 superado. pmbootstrap 3.12.1 con configuración y copia de
pmaports separadas, canal edge, UI console, systemd; `kconfig check` real
pasó; kernel compilado con el clang de Alpine en ~21 min (16 hilos),
`uname -r` = `7.3.0-rc6-zumapro`. El repo del kernel se renombró en GitHub a
`derekross/linux-omamobile` (la URL antigua redirige) y la carpeta del
tarball es `linux-omamobile-<commit>`; se corrigió el `builddir`. El tarball
del commit fijado es idéntico fichero a fichero al árbol del hito 1. Ensayo
sin tocar `userdata`: solo las cinco `_b` con el initramfs de Nura (15 MB
zstd, recomprimido a lz4 legacy); el ABL lo aceptó, gadget USB a los ~28 s,
ping a `172.16.43.1`, el initramfs cayó al debug shell por no encontrar raíz,
y Android arrancó después con sus datos intactos. Después, `userdata`
flasheado desde el bootloader con el sparse (834 MB, 4 trozos, ~23 s): Nura
edge llega a `login:` en pantalla; por SSH, sistema `running`, 0 unidades
fallidas, raíz ext4 en loop sobre `userdata` (sector 4096) ampliada a
221,6 GiB, 15,1 GiB de RAM, 8 CPU, slot `_b`, guardia del UFS `--check` = 0.
Datos de Android perdidos (esperado); slot A, bootloader, radio y `vbmeta`
sin tocar. Problemas: contador de intentos del slot B sin resolver (hay que
hacer `set_active b` antes de agotarlo); en el primer arranque el PC no
enumeró el USB (errores `-71`), no se repitió; las "caídas de USB" eran del
PC (IP estática perdida en cada reenumeración; perfil de NetworkManager por
MAC), y las hipótesis de módulos y del religado de la UDC se descartaron en
vivo; logind ve la tecla de encendido pero no apaga ni reinicia, y desde Linux
Encendido + Volumen − no lleva a fastboot (se llegó con un reinicio forzado
por botones manteniendo luego Volumen −, combinación exacta sin anotar); sin
táctil; sin `/sys/class/power_supply`; el debug shell en `ttyGS0` sale
entremezclado, telnet funciona; solo cargan `clk-acpm` y `gs101_acpm_tmu`, y
cpufreq funciona. Estado: Nura en `userdata` arrancando desde el slot B;
`vendor_boot_b` lleva de momento `pmos.debug-shell`.

---

## 2026-11-25 — Touchscreen works / El táctil funciona

Kernel package [`linux-google-zumapro`](../pmaports/device/testing/linux-google-zumapro/)
now at `pkgrel=1`, with a fourth patch,
`0004-arm64-dts-komodo-enable-the-Synaptics-S3908-touchscreen.patch`.

What the hardware is:

- The touch controller is a **Synaptics S3908 over SPI** (TouchComm protocol)
  on `spi@111d0000`. The board DTS from PR #276 already described the node
  `touchscreen@0` (`syna,s3908`), but with `status = "disabled"`, by the PR's
  policy for experimental devices, not because of a reported failure.
- The `synaptics_tcm` SPI driver comes with the Omamobile tree (it is not
  mainline) and was already built into our kernel
  (`CONFIG_TOUCHSCREEN_SYNAPTICS_TCM_SPI=y`). No external firmware is needed:
  the chip boots the firmware in its own flash.
- The node's rails (LDOs of the S2MPG14 PMIC, through ACPM), reset and IRQ
  match the stock DTBO.

The change is removing that one `status = "disabled"` line (patch 0004; it
also updates two comments). First it was tried by changing only the DTB in
`vendor_kernel_boot_b`; then it went into the package (`pkgrel=1`) and was
reinstalled.

Result on our unit:

- dmesg: `synaptics-tcm spi0.0: S3908GA1B0-15.0, TouchComm v1`, 13440x29920,
  10 objects; input device "Synaptics TouchComm Touchscreen".
- The probe does not delay the boot (~0.6 s of kernel time).
- With the on-screen keyboard of the initramfs debug shell (buffyboard), the
  owner typed by touch; the chip's interrupt counter rises with the touches.

UI and reinstall:

- The UI changed from `console` to `buffyboard` (framebuffer console with an
  on-screen keyboard), and Nura was reinstalled (`userdata` reflashed plus the
  five `_b` images).
- It boots, SSH over USB after ~26 s, and the owner logged in at the
  on-screen `login:` by touching the keyboard, with no cable: the first local
  session without a PC.

Problems and limits:

1. `systemd-firstboot.service` fails on the first boot of every new install
   ("Failed to set up standard input": it has no input console) and leaves
   the system `degraded` for that boot. On the previous install it did not
   come back on later boots.
2. Not tested: real multitouch, palm rejection, accuracy/calibration, touch
   across suspend/resume, use with a graphical UI.
3. Unchanged: no GPU, no backlight, no battery/charging, no WiFi; the slot-B
   retry counter is still unresolved; the buttons still do nothing.
4. Our own mistake: a temporary diagnostic service installed by hand on the
   root filesystem left `/etc` and `/usr` with the wrong owner, which broke
   `sudo`. It was repaired from the debug shell, and the later reinstall left
   the system clean. Lesson: never extract a tar as root while preserving
   foreign ownership.

Device state after this entry: Nura (`buffyboard` UI, kernel package
`pkgrel=1`) on `userdata`, booting from slot B; `vbmeta_b` stock; slot A
untouched.
`vendor_boot_b` no longer carries `pmos.debug-shell` (normal command line).
The 0004 patch text still says "Not tested on this exact tree": it is kept
byte-identical to what was built; it has since been tested on our unit as
described above. / `vendor_boot_b` ya no lleva `pmos.debug-shell`; el texto
del parche 0004 se conserva idéntico al compilado aunque ya está probado.

Resumen: el táctil funciona. Es un Synaptics S3908 por SPI (TouchComm) en
`spi@111d0000`; el nodo `touchscreen@0` (`syna,s3908`) ya estaba en el DTS de
la placa, pero con `status = "disabled"` por política del PR #276. El driver
`synaptics_tcm` (SPI) viene en el árbol de Omamobile, no es mainline, y ya
estaba integrado en el kernel (`CONFIG_TOUCHSCREEN_SYNAPTICS_TCM_SPI=y`); no
hace falta firmware externo porque el chip arranca el de su propia flash.
Raíles (LDO del PMIC S2MPG14 vía ACPM), reset e IRQ coinciden con el DTBO de
fábrica. El cambio es quitar esa línea (parche 0004): primero se probó
cambiando solo el DTB de `vendor_kernel_boot_b` y después se integró en el
paquete (`pkgrel=1`) y se reinstaló. En dmesg: `S3908GA1B0-15.0, TouchComm
v1`, 13440x29920, 10 objetos; dispositivo de entrada "Synaptics TouchComm
Touchscreen"; el probe no retrasa el arranque (~0,6 s de kernel). Con el
teclado en pantalla del debug shell del initramfs (buffyboard) el dueño
escribió tocando, y el contador de interrupciones del chip sube con los
toques. La UI pasó de `console` a `buffyboard` y se reinstaló Nura (`userdata`
reflasheado y las cinco `_b`): arranca, SSH por USB a los ~26 s, y el dueño
inició sesión en el `login:` tocando, sin cable: la primera sesión local sin
PC. `systemd-firstboot.service` falla en el primer arranque de cada
instalación nueva (no tiene consola de entrada) y deja ese arranque en
`degraded`; en la instalación anterior no reapareció después. Sin probar:
multitáctil real, rechazo de palma, precisión/calibración,
suspensión/reanudación, UI gráfica. Sigue sin GPU, backlight, batería/carga
ni WiFi; el contador del slot B sigue sin resolver y los botones sin acción.
Error propio: un servicio temporal de diagnóstico instalado a mano en la raíz
dejó `/etc` y `/usr` con propietario incorrecto y rompió `sudo`; se reparó
desde el debug shell y la reinstalación lo dejó limpio. Lección: no extraer un
tar como root conservando propietarios ajenos.

---

## 2026-11-25 — Milestone 3: Phosh on KMS, GPU, battery readout, reboot to bootloader / Hito 3: Phosh sobre KMS, GPU, lectura de batería, reinicio al bootloader

Procedure: [MILESTONE-3.md](MILESTONE-3.md). Packages updated in
[`../pmaports/device/testing/`](../pmaports/device/testing/):
`linux-google-zumapro` `pkgrel=2` (11 patches on commit `ffd33b7`) and
`device-google-komodo` `pkgrel=3`.

New kernel patches:

- 0005 and 0006: MAX77779 fuel gauge (read-only driver) and charger on
  `hsi2c6` (`i2c@108d0000`), both drivers already built as modules.
- 0007: `syscon-reboot-mode` on the PMU, together with `reboot=warm` on the
  command line (a cold PSCI reset clears the reboot reason register).
- 0008: a minimal `google,km4` panel driver, brightness only (backlight range
  0..3271, 0 = pixel off); config gains `CONFIG_DRM_PANEL_GOOGLE_KM4=m`.
- 0009: DSIM0 as a DCS command host for the panel, with no port to DECON0.
- 0010: `gs-decon` keeps komodo's boot framebuffer aperture
  (`hold_boot_fb`), so the `simple-framebuffer` can stay in the DT as a
  fallback without a second, phantom output.
- 0011: Mali-G715 node, `cmu_g3d` and the 150/302 MHz OPP table enabled.

Results on our unit:

- **Display:** from the `simpledrm` console to real KMS: `gs-decon` stage 2
  (`gs_decon.stage=2 gs_decon.fbdev=1 gs_dsim_cmd.allow_tx=1`, from the
  device package's command line), 60 Hz. Brightness control works.
- **Battery:** the fuel gauge reads the charge percentage and a design
  capacity of 5035 mAh. The charger is detected. From a PC USB port the input
  is 500 mA: the battery holds, it barely charges.
- **Reboot to the bootloader:** `reboot bootloader` reaches fastboot with no
  buttons and without spending an extra slot B retry.
- **GPU:** Mali-G715 with Panthor and the CSF firmware
  `arm/mali/arch11.8/mali_csffw.bin` (Alpine package `linux-firmware-arm`).
  Mesa 26.3.1 reports "Mali-G715 MC7 (Panfrost)", OpenGL ES 3.1. At first
  `panthor` was blacklisted in the device package, out of caution: G3D has no
  power domain driver and depends on the bootloader leaving it on. After
  loading it by hand and testing it, the blacklist was dropped (device
  `pkgrel=3`); it now loads by itself ~5 s into the boot. No performance
  measurements.
- **UI:** Nura reinstalled with Phosh (phoc, greetd with phrog, stevia
  keyboard) through pmbootstrap (`ui = phosh`, extra packages
  `linux-firmware-arm,mesa-dri-gallium,mesa-utils,kmscube`): graphical login
  by touch, GPU-accelerated. After a clean reboot, zero failed systemd units.
- **Kernel updates without reinstalling:** copy the kernel apk to the phone,
  `apk add --allow-untrusted --no-network`, let the phone regenerate its boot
  files, copy them back, rebuild the images with `mkimages-pmos.sh` and flash
  only `boot_b`, `vendor_boot_b` and `vendor_kernel_boot_b`.

Problems and limits:

1. Found and fixed: `buffyboard.service` (the text console's on-screen
   keyboard) was still active under Phosh. It got the same touches and
   injected key presses, so phantom characters showed up in the PIN field.
   Fixed with `systemctl disable --now buffyboard`. Still to find out: what
   enables it on a Phosh install.
2. WiFi/Bluetooth: Broadcom BCM4390 over PCIe (ID `14e4:4438`); mainline
   `brcmfmac` does not support it. Not working.
3. Audio, modem, cameras: not working, not started.
4. Managed USB-C (TCPC): a patch is prepared, not integrated.
5. Slot B retry counter: unchanged, each boot spends 1 of 3, reloaded with
   `fastboot set_active b`. The device package now carries a
   `komodo-bootctl` tool as source; it is not compiled and has never been
   used to write `devinfo`.
6. Buttons: no verified action. Power off: not tested.
7. USB: the `error -71` enumeration failure seen once in Milestone 2 came
   back on some boots. Intermittent, cause unknown.
8. The commit messages of patches 0008–0011 still say they are untested
   (and 0011 that `panthor` is blacklisted, also in a DTS comment);
   they are kept as built, and the docs describe the current state.

Publication note: the `From:` line of all 11 kernel patches (including the
already published 0001–0004) was normalised to the project's public author
identity, and the patch checksums in the APKBUILD were updated accordingly.
The patch bodies are unchanged.

Device state after this entry: Nura with Phosh (kernel package `pkgrel=2`,
device package `pkgrel=3`) on `userdata`, booting from slot B; `vbmeta_b`
stock; slot A untouched.

Resumen: hito 3. Paquete del kernel `linux-google-zumapro` `pkgrel=2`, 11
parches sobre `ffd33b7`: 0005 y 0006 fuel gauge (driver de solo lectura) y
cargador MAX77779 en `hsi2c6`; 0007 `syscon-reboot-mode` con `reboot=warm`;
0008 driver mínimo del panel `google,km4` (solo brillo, rango 0..3271, 0 =
píxel apagado; `CONFIG_DRM_PANEL_GOOGLE_KM4=m`); 0009 DSIM0 como host DCS;
0010 `hold_boot_fb` en `gs-decon`; 0011 Mali-G715 (nodo `gpu`, `cmu_g3d`,
OPP). Paquete del dispositivo `pkgrel=3`. Pantalla: de consola `simpledrm` a
KMS real (`gs-decon` stage 2, cmdline `gs_decon.stage=2 gs_decon.fbdev=1
gs_dsim_cmd.allow_tx=1`), 60 Hz, control de brillo funcionando. Batería: el
fuel gauge lee el porcentaje y la capacidad de diseño (5035 mAh); el
cargador se detecta; desde un USB de PC la entrada es de 500 mA: mantiene,
casi no carga. `reboot bootloader` llega a fastboot sin botones y sin gastar
un intento extra del slot. GPU: Mali-G715 con Panthor y el firmware CSF
`arm/mali/arch11.8/mali_csffw.bin` (paquete `linux-firmware-arm`); Mesa
26.3.1 la presenta como "Mali-G715 MC7 (Panfrost)", OpenGL ES 3.1. Primero
estuvo en lista negra por prudencia (G3D no tiene driver de power domain y
depende de que el bootloader lo deje encendido); tras probarla se quitó la
lista negra (dispositivo `pkgrel=3`) y se carga sola a los ~5 s. Sin medidas
de rendimiento. Interfaz: Phosh (phoc, greetd/phrog, teclado stevia)
instalado con pmbootstrap (`ui = phosh` y los paquetes extra
`linux-firmware-arm,mesa-dri-gallium,mesa-utils,kmscube`), login gráfico
táctil acelerado por GPU; tras un reinicio limpio, cero unidades fallidas.
Fallo encontrado y resuelto: `buffyboard.service` seguía activo bajo Phosh,
recibía los mismos toques e inyectaba teclas (caracteres fantasma en el
PIN); solución `systemctl disable --now buffyboard`; pendiente averiguar qué
lo habilita. Kernel nuevo sin reinstalar: copiar el apk, `apk add
--allow-untrusted --no-network`, el teléfono regenera las imágenes de
arranque, se recogen, se reempaquetan con `mkimages-pmos.sh` y se flashean
solo `boot_b`, `vendor_boot_b` y `vendor_kernel_boot_b`. No funciona
todavía: WiFi/BT (BCM4390 por PCIe, `14e4:4438`, sin soporte en el
`brcmfmac` de mainline), audio, módem, cámaras, USB-C gestionado (parche
preparado, sin integrar), contador del slot B (la herramienta
`komodo-bootctl` va como fuente, sin compilar ni usar para escribir),
botones sin acción comprobada, apagado sin probar, y el fallo USB `error -71`
reaparece de forma intermitente en algunos arranques (causa desconocida).
Los mensajes de los parches 0008–0011 y un comentario del DTS del 0011
siguen diciendo que no están probados o que `panthor` está en lista negra;
se conservan como se compilaron. Nota de publicación: la línea `From:` de
los 11 parches (también los 0001–0004 ya publicados) se normalizó a la
identidad pública del proyecto y se actualizaron sus sumas en el APKBUILD;
el contenido de los parches no cambia.
