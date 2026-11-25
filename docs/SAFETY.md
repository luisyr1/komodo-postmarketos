# Safety rules / Reglas de seguridad

Read this whole file before flashing anything. No warranty: you may lose data
or brick your device.

Lee este fichero entero antes de flashear nada. Sin garantía: puedes perder
datos o brickear el dispositivo.

## Before anything / Antes de nada

1. Update stock Android to the build documented in [UNLOCK.md](UNLOCK.md)
   first (or newer, knowing the `komodo` kernel was only reported on that one).
   / Actualiza Android stock al build documentado en UNLOCK.md (o uno más
   nuevo, sabiendo que el kernel de `komodo` solo se ha reportado en ese).
   **Anti-rollback:** never flash a factory image or OTA older than the one
   installed.
2. **Same build on both slots.** An OTA only writes the inactive slot. Sideload
   the same full OTA **twice** (once per slot) so both slots carry the same
   build and the same bootloader. Check with `fastboot getvar` before going on.
   `fastboot getvar version-bootloader` (and the preflight of
   `flash-slot-b.sh`, which cannot check slot B's bootloader or Android build)
   only reports the **current** slot, so after each sideload read
   `ro.bootloader` and `ro.boot.slot_suffix` in Android: both slots must show
   the same bootloader, and this must be done **before** the first
   `set_active b` (in practice, before flashing slot B). Activating a slot with
   an older bootloader risks anti-rollback problems. Procedure:
   [UNLOCK.md](UNLOCK.md). / **Mismo build en ambos slots.** `version-bootloader`
   (y el preflight de `flash-slot-b.sh`, que no puede comprobar el bootloader
   ni el build del slot B) solo informa del slot **actual**: tras cada sideload
   lee `ro.bootloader` y `ro.boot.slot_suffix` en Android; ambos slots tienen
   que dar el mismo bootloader, y hay que comprobarlo **antes** del primer
   `set_active b` (en la práctica, antes de flashear el slot B).
3. **Check the active slot: Android must be active and verified on slot A.**
   Every rule in this project ("Android on A, Linux on B") assumes it. The
   double sideload leaves the phone active on the slot where it started, so the
   active slot may well be B. In fastboot:

   ```sh
   fastboot getvar current-slot
   ```

   If it prints `b`: run `fastboot --set-active=a`, boot Android completely and
   confirm (e.g. `adb shell getprop ro.boot.slot_suffix` gives `_a`) before
   going any further. Do not flash or unlock anything until this holds.

   With the bootloader still **locked**, `fastboot --set-active` may be
   rejected (not verified by us). In that case either sideload the same full
   OTA once more (each sideload switches the active slot) and check again, or
   unlock first and switch the slot afterwards. Verified on our unit: we
   started on slot A, the first sideload left B active and the second left A
   active.

   **Comprueba el slot activo: Android debe estar activo y verificado en el
   slot A.** Todas las reglas del proyecto ("Android en A, Linux en B") lo
   suponen. El doble sideload deja el teléfono activo en el slot donde empezó,
   así que el activo puede ser el B. Comprueba `fastboot getvar current-slot`;
   si da `b`, ejecuta `fastboot --set-active=a`, arranca Android del todo y
   verifícalo (`ro.boot.slot_suffix` = `_a`) antes de seguir. Con el
   bootloader aún **bloqueado**, `--set-active` puede ser rechazado (no
   verificado por nosotros); en ese caso, haz sideload del mismo OTA completo
   una vez más (cada sideload cambia el slot activo) y vuelve a comprobarlo, o
   desbloquea primero y cambia de slot después. Verificado en nuestra unidad:
   empezamos en el slot A, el primer sideload dejó activo el B y el segundo
   dejó activo el A.
4. Verify the SHA-256 of every download against Google's official table.
5. Unlocking the bootloader wipes all user data. Back up personal data first.
6. **Disable automatic system updates** (Developer options) once both slots
   match, and **do not accept any OTA manually** either. An Android OTA is
   written to the inactive slot, which (with Android active on A, see step 3)
   is slot B, the one reserved for Linux.
7. Make a **private** backup of the identity/calibration partitions: `efs`,
   `efs_backup`, `modem_userdata`, `persist`, `devinfo`, `mfg_data`. They
   contain the IMEI and per-device calibration. In practice we copy every
   partition except `userdata` and `super`. / Copia **privada** de las
   particiones de identidad/calibración (`efs`, `efs_backup`,
   `modem_userdata`, `persist`, `devinfo`, `mfg_data`); en la práctica
   copiamos todas salvo `userdata` y `super`.
   - Without root they cannot be read from Android; in this project the copy is
     taken from the RAM-only Linux of Milestone 1, **before** anything writes
     to `userdata` or to any identity partition. (Milestone 1 does flash the
     five slot-B boot partitions before the copy can be taken, because
     without root they cannot be read from Android.) / Sin root no se pueden
     leer desde Android: la copia se hace desde el Linux en RAM del hito 1,
     **antes** de escribir nada en `userdata` o en una partición de identidad
     (el hito 1 sí flashea antes las cinco particiones de arranque del slot B).
   - Store them outside this repository (e.g. encrypted offline storage).
   - **Never** commit, upload or share them. `.gitignore` blocks common names,
     but it is not a substitute for care.

## Flashing rules / Reglas de flasheo

- Before every flashing session, confirm with `fastboot getvar current-slot`
  that Android is active on slot A (step 3 above).
- After an OTA, before flashing or unlocking, check
  `fastboot getvar snapshot-update-status`: it must print `none` (a Virtual
  A/B merge may still be pending otherwise). Do not use
  `fastboot snapshot-update cancel`. *(Precaution; not verified on our unit.)*
  / Tras un OTA, antes de flashear o desbloquear, comprueba que
  `fastboot getvar snapshot-update-status` da `none`, y no uses
  `fastboot snapshot-update cancel` *(precaución no verificada en nuestra
  unidad)*.
- Flash **only slot B**. Stock Android stays on **slot A** as the fallback.
- Allowed targets (slot B only): `boot_b`, `init_boot_b`, `vendor_boot_b`,
  `vendor_kernel_boot_b`, `dtbo_b`. From Milestone 2 on, also `userdata` (see
  the trade-off below).
- Custom images need an **AVB hash footer**: stock `vbmeta` chains `boot` and
  `init_boot` and lists `dtbo`, `vendor_boot`, `vendor_kernel_boot` as hash
  descriptors (factory-image analysis). **Verified on our unit:** images with a
  hash footer signed with AOSP's public test key boot with stock `vbmeta_b`
  and the bootloader unlocked (Milestone 1).
- Before the first `set_active b`, verify that both slots carry the same
  bootloader (step 2 above): the scripts cannot check slot B's. / Antes del
  primer `set_active b`, verifica que ambos slots llevan el mismo bootloader
  (paso 2): los scripts no pueden comprobar el del slot B.
- **Verified on our unit:** flashing any `_b` partition sets
  `slot-successful:b=no`; `set_active b` gives 3 retries; our Linux never marks
  B successful, and once the retries ran out the bootloader went back to slot
  A by itself. / **Verificado en nuestra unidad:** flashear cualquier `_b`
  pone `slot-successful:b=no`; `set_active b` da 3 intentos; nuestro Linux
  nunca marca B como correcto y, agotados los intentos, el bootloader volvió
  solo al slot A.
- **Never flash:** `bootloader`, `radio`, `vbmeta`, `devinfo`, `efs`,
  `persist`, or **anything on slot A**.
- **Never** run `flash-all.sh` and **never** use `fastboot -w` (wipe).
- **Never run `fastboot flashing lock`** (re-lock) while any non-stock image is
  on either slot: it can hard-brick the phone, and re-locking also wipes all
  data. / **Nunca ejecutes `fastboot flashing lock`** con imágenes no stock en
  algún slot: puede brickear el teléfono sin remedio, y volver a bloquear
  también borra los datos.
- Correction: third parties reported that the ABL ignores the `vendor_boot`
  cmdline. **Verified on our unit, it does not:** with bootloader
  `ripcurrentpro-17.0-16433847` the ABL appends it after the DTB bootargs (and
  then adds its own parameters). / Corrección: verificado en nuestra unidad
  que el ABL **sí** añade la cmdline de `vendor_boot`.
- `fastboot boot` (RAM boot) is reported **not viable** on `komodo` by third
  parties (not verified by us). The RAM-only approach is therefore to flash the
  slot-B images with a rescue initramfs that does not mount `userdata`
  read-write.
- Never commit logs, `getprop` output or bug reports without scrubbing serial,
  IMEI, MAC and account data.

## The `userdata` trade-off / La contrapartida de `userdata`

There is only **one** `userdata` partition (not A/B), shared by both slots.
Once Linux keeps its root there (Milestone 2), booting stock Android on slot A
is reported by third parties to reformat `userdata` (not verified by us), and
then **the Linux root is lost**. Back up anything you need from the Linux side
before switching to slot A.

Solo hay **un** `userdata` (no es A/B) y lo comparten ambos slots. Cuando la
raíz de Linux viva ahí (hito 2), según terceros arrancar Android stock en el
slot A lo reformatea (no verificado por nosotros) y entonces **se pierde la
raíz Linux**.

## Returning to stock / Vuelta a stock

1. Switch the active slot back to A (`fastboot --set-active=a`) and reboot.
   With our own images on slot B, slot B's recovery is **not** the stock one:
   do not use it. Get to fastboot first (if Linux hangs, hold **Power +
   Volume Down**; verified by us on `komodo`), run
   `fastboot --set-active=a`, and use slot A's recovery/Android.
2. If slot A also fails, sideload from recovery the **same or newer** official
   full OTA (never older: anti-rollback), as in [UNLOCK.md](UNLOCK.md). Still
   no `flash-all.sh` and no `-w`.
3. Keep the five stock images (`boot`, `init_boot`, `vendor_boot`,
   `vendor_kernel_boot`, `dtbo`) extracted from the factory image of the
   **same** build, so slot B can be restored with `fastboot flash <part>_b`.
4. Only restore identity/calibration partitions (`efs`, `efs_backup`,
   `modem_userdata`, `persist`, `devinfo`, `mfg_data`) from your private
   backup if they are actually damaged, and only to the same physical unit.

Con imágenes propias en el slot B, el recovery de B no es el de stock: entra
primero en fastboot (si Linux se cuelga, mantén **Encendido + Volumen −**;
combinación verificada por nosotros en `komodo`), ejecuta
`fastboot --set-active=a` y usa el recovery/Android del slot A. Conserva las
cinco imágenes stock (`boot`, `init_boot`, `vendor_boot`, `vendor_kernel_boot`,
`dtbo`) de la imagen de fábrica del **mismo** build para restaurar el slot B
con `fastboot flash <part>_b`.

## Before every commit or push / Antes de cada commit o push

This repository is public. Run through this list every time:

1. Review `git status` (and `git status --ignored` when in doubt): every new
   file must be one you meant to publish.
2. Never use `git add -f` without inspecting exactly what you are forcing past
   `.gitignore`.
3. Check author and committer identity:
   `git log --format='%an <%ae> | %cn <%ce>'`. Use the identity you want to be
   public (e.g. a no-reply address).
4. Never paste raw `getprop`, `fastboot getvar`, `dmesg`, `lsusb` or similar
   output. Quote only the lines needed, with serial, IMEI, MAC, board serials
   and account data removed.
5. Strip EXIF/metadata from every image (e.g. `exiftool -all= file.jpg`) and
   check screenshots for on-screen identifiers before adding them with an
   explicit `.gitignore` exception.
6. Review `git diff --cached` for absolute paths, user names, hostnames and
   e-mail addresses.

Este repositorio es público. Antes de cada commit o push: revisa `git status`;
no uses `git add -f` sin mirar qué fuerzas; comprueba autor y committer con
`git log --format='%an <%ae> | %cn <%ce>'`; no pegues salidas en bruto de
`getprop`, `getvar`, `dmesg` ni `lsusb`; quita el EXIF de las imágenes y añádelas
con excepción explícita; y revisa `git diff --cached` en busca de rutas, nombres
de usuario y correos.

## Linux flashing procedure / Procedimiento de flasheo de Linux

The RAM-only procedure verified on our unit (Milestone 1) is in
[MILESTONE-1.md](MILESTONE-1.md), with scripts in
[../scripts/](../scripts/README.md). Installing Nura on `userdata`
(Milestone 2, verified on our unit on 2026-11-25; **flashing `userdata` wipes
all Android data**) is in [MILESTONE-2.md](MILESTONE-2.md). The update and
unlock steps are in [UNLOCK.md](UNLOCK.md).

El procedimiento solo en RAM verificado en nuestra unidad (hito 1) está en
[MILESTONE-1.md](MILESTONE-1.md), con los scripts en
[../scripts/](../scripts/README.md). Instalar Nura en `userdata` (hito 2,
verificado en nuestra unidad el 2026-11-25; **flashear `userdata` borra todos
los datos de Android**) está en [MILESTONE-2.md](MILESTONE-2.md). La
actualización y el desbloqueo están en [UNLOCK.md](UNLOCK.md).
