# Update and unlock / Actualización y desbloqueo

What we did on 2026-11-24 to take our unit from an old Android Beta build to
stable Android 17 on **both** slots, and then unlock the bootloader. Written so
it can be reproduced; it is **not** a Linux install guide (nothing Linux-related
is flashed here).

Lo que hicimos el 2026-11-24 para pasar nuestra unidad de un build antiguo de
Android Beta a Android 17 estable en **ambos** slots, y después desbloquear el
bootloader. Está escrito para poder reproducirlo; **no** es una guía de
instalación de Linux (aquí no se flashea nada de Linux).

Details marked *(standard step, not recorded literally in our session)* are
the usual Pixel procedure, included for completeness; everything else is what
we observed. / Lo marcado como *(paso estándar, no registrado literalmente en
nuestra sesión)* es el procedimiento habitual de Pixel; el resto es lo que
observamos.

[English](#english) · [Español](#español)

---

## English

### Risk warning

- Unlocking the bootloader **wipes all user data**. Back up first.
- A wrong image, an interrupted update or an older build (anti-rollback) can
  leave the phone unbootable. **No warranty**; you are responsible for your
  device. Read [SAFETY.md](SAFETY.md) first.
- `getprop` and `fastboot getvar all` print the serial number and other unique
  identifiers. Read them on your screen; **never** paste the raw output into
  issues, logs or this repository. Query single variables instead of `all`.

### Requirements

- A computer with current `adb` and `fastboot` (Android platform-tools).
- A good USB cable, phone charged above 50% *(standard step, not recorded
  literally in our session)*.
- The official **full OTA** zip for `komodo` (not the factory image, not an
  incremental OTA), downloaded from Google (`dl.google.com`).

Build used by us: Android 17 stable `CP4A.261105.040.A1`, security patch
2026-11-05. According to the Omamobile `komodo` bring-up PRs, it is the build
on which the `komodo` kernel was booted (not verified by us).

### 1. Check where you are

With USB debugging enabled in Android:

```sh
adb shell getprop ro.build.id
adb shell getprop ro.build.version.security_patch
adb shell getprop ro.bootloader
adb shell getprop ro.boot.slot_suffix
```

Our unit started on an old Android Beta program build (Android 16, patch
2025-08). The target must be **newer** than what is installed (anti-rollback).

### 2. Verify the download

```sh
sha256sum <ota-file>.zip
```

Compare with the SHA-256 published by Google for that file. Our files matched
the values quoted in the Omamobile PR; we did **not** cross-check them against
Google's own table, and you should.

### 3. Sideload the full OTA, first time

```sh
adb reboot recovery
```

Pixel recovery first shows an Android robot with **"No command"**. To see the
menu, hold **Power** and press **Volume Up** once, then release both. Move with
the volume keys and select with Power *(standard step, not recorded literally
in our session)*.

In recovery choose "Apply update from ADB", then:

```sh
adb sideload <ota-file>.zip
```

Wait until it finishes, reboot and let Android boot completely. The update is
written to the inactive slot, which becomes the active one after a successful
boot.

Then read which slot booted and **its** bootloader:

```sh
adb shell getprop ro.boot.slot_suffix
adb shell getprop ro.bootloader
```

On our unit, after the first sideload the phone booted from slot B and
`ro.bootloader` was `ripcurrentpro-17.0-16433847`.

### 4. Sideload the same OTA a second time

Repeat step 3 with the **same** file. This writes the other slot, so both slots
end up with the same build and the same bootloader. Why it matters: with
mismatched slots, falling back to the other slot could mean an older
bootloader (anti-rollback risk) or a build where the `komodo` kernel has not
been tested.

Let Android boot completely again, and read the same two properties
(`ro.boot.slot_suffix`, `ro.bootloader`): now they belong to the **other**
slot. On our unit, after the second sideload the phone booted from slot A and
`ro.bootloader` was the same, `ripcurrentpro-17.0-16433847`.

**Both reads must give the same bootloader.** This per-slot read is the only
check of slot B's bootloader in this procedure: `fastboot getvar
version-bootloader` (step 5, and the preflight of `flash-slot-b.sh`) only
reports the current slot. Do it **before** flashing anything to slot B; once
slot B carries Linux it no longer boots Android. If the two values differ, do
not go on: activating a slot with an older bootloader risks anti-rollback
problems.

### 5. Check both slots

```sh
adb reboot bootloader
fastboot getvar current-slot
fastboot getvar slot-successful:a
fastboot getvar slot-successful:b
fastboot getvar version-bootloader
fastboot getvar version-baseband
```

Our result: both slots successful; bootloader `ripcurrentpro-17.0-16433847`;
baseband `g5400c-260818-261007-B-16536938`. `version-bootloader` here is the
bootloader of the **current** slot only; that both slots carry it comes from
the `ro.bootloader` reads in steps 3 and 4.

**Active slot must be A before going on.** Every rule in this project assumes
stock Android active and verified on slot A, with slot B reserved for Linux.
The double sideload leaves the phone active on the slot where it started, so
`current-slot` may print `b`. In that case:

```sh
fastboot --set-active=a
fastboot reboot
```

Let Android boot completely and verify (`adb shell getprop
ro.boot.slot_suffix` must print `_a`) before step 6. Our unit was on slot A.

With the bootloader still **locked**, `fastboot --set-active` may be rejected
(not verified by us). In that case either sideload the same full OTA once more
(each sideload switches the active slot) and check again, or unlock first
(step 7) and switch the slot afterwards. Verified on our unit: we started on
slot A, the first sideload left B active and the second left A active.

Also check, after the OTA and before unlocking or flashing:

```sh
fastboot getvar snapshot-update-status   # must print: none
```

If it does not print `none`, boot Android and let it finish the update before
going on. Do not use `fastboot snapshot-update cancel`. *(Precaution; not
verified on our unit.)*

### 6. Prepare Android

Boot Android, then in Developer options:

- enable **OEM unlocking**. On carrier-locked units this switch is greyed out
  and cannot be enabled; it may also stay greyed out until the phone has been
  connected to the internet *(standard behaviour, not recorded literally in our
  session)*;
- enable **USB debugging**;
- **disable automatic system updates**. That alone is **not** enough: do not
  accept any OTA manually either. An Android OTA is written to the inactive
  slot, which (with Android active on A) is slot B, the one reserved for Linux.

### 7. Unlock (wipes everything)

**`fastboot flashing unlock` erases all user data on the phone.** Back up
first.

```sh
adb reboot bootloader
fastboot flashing unlock   # WIPES ALL DATA
```

Confirm on the phone with the volume and power buttons *(standard step, not
recorded literally in our session)*. The phone is wiped. After setup, enable
USB debugging again for step 8 and always disable automatic system updates
again after the wipe, before connecting to Wi-Fi if possible (the wipe resets
that setting); still accept no OTA.

### 8. Check the result

```sh
adb shell getprop ro.boot.verifiedbootstate   # expected: orange
adb shell getprop ro.boot.slot_suffix
```

Our state afterwards: active slot A, both slots successful,
`verifiedbootstate` orange.

### What we did not do

- No `flash-all.sh`, no `fastboot -w`.
- **Never run `fastboot flashing lock`** (re-lock) while any non-stock image is
  on either slot: it can hard-brick the phone, and re-locking also wipes all
  data.
- Nothing flashed to `bootloader`, `radio`, `vbmeta`, `devinfo`, `efs` or
  `persist` by hand.
- The private backup of IMEI/calibration partitions was **not** done here: it
  needs root. It was taken later from the RAM-only Linux of Milestone 1
  ([MILESTONE-1.md](MILESTONE-1.md)).

---

## Español

### Aviso de riesgo

- Desbloquear el bootloader **borra todos los datos**. Haz copia antes.
- Una imagen equivocada, una actualización interrumpida o un build más antiguo
  (anti-rollback) pueden dejar el teléfono sin arrancar. **Sin garantía**; el
  dispositivo es responsabilidad tuya. Lee antes [SAFETY.md](SAFETY.md).
- `getprop` y `fastboot getvar all` muestran el número de serie y otros
  identificadores únicos. Léelos en tu pantalla; **nunca** pegues la salida en
  bruto en issues, logs ni en este repositorio. Consulta variables sueltas en
  vez de `all`.

### Requisitos

- Un ordenador con `adb` y `fastboot` actuales (platform-tools de Android).
- Un buen cable USB y el teléfono con más del 50 % de batería *(paso estándar,
  no registrado literalmente en nuestra sesión)*.
- El zip del **OTA completo** oficial de `komodo` (no la imagen de fábrica ni
  un OTA incremental), descargado de Google (`dl.google.com`).

Build usado: Android 17 estable `CP4A.261105.040.A1`, parche 2026-11-05. Según
los PR de bring-up de `komodo` de Omamobile, es el build en el que se arrancó
el kernel de `komodo` (no verificado por nosotros).

### Pasos

Los comandos son los mismos de la sección inglesa.

1. **Comprobar el punto de partida** con `adb shell getprop` (`ro.build.id`,
   `ro.build.version.security_patch`, `ro.bootloader`, `ro.boot.slot_suffix`).
   Nuestra unidad venía de un build antiguo del programa Android Beta
   (Android 16, parche 2025-08). El destino tiene que ser **más nuevo**
   (anti-rollback).
2. **Verificar la descarga** con `sha256sum`. Los nuestros coincidieron con
   los del PR de Omamobile; **no** los cotejamos con la tabla de Google, y
   conviene hacerlo.
3. **Primer sideload:** `adb reboot recovery`. El recovery de Pixel muestra
   primero un robot con **"No command"**: para ver el menú, mantén **Encendido**
   y pulsa una vez **Volumen +**, y suelta ambos *(paso estándar, no registrado
   literalmente en nuestra sesión)*. Luego "Apply update from ADB",
   `adb sideload <fichero-ota>.zip`. Reiniciar y dejar que Android arranque del
   todo: el OTA se escribe en el slot inactivo, que pasa a activo tras un
   arranque correcto. Después, leer qué slot arrancó y **su** bootloader con
   `adb shell getprop ro.boot.slot_suffix` y `adb shell getprop
   ro.bootloader`. En nuestra unidad, tras el primer sideload arrancó desde el
   slot B con `ro.bootloader` = `ripcurrentpro-17.0-16433847`.
4. **Segundo sideload del mismo fichero**, para escribir el otro slot y dejar
   ambos con el mismo build y el mismo bootloader. Si los slots no coinciden,
   volver al otro slot podría significar un bootloader más antiguo (riesgo de
   anti-rollback) o un build en el que no se ha probado el kernel de `komodo`.
   Dejar que Android arranque del todo otra vez y repetir las dos lecturas,
   que ahora son del **otro** slot. En nuestra unidad, tras el segundo
   sideload arrancó desde el slot A con el mismo `ro.bootloader`.
   **Las dos lecturas tienen que dar el mismo bootloader.** Es la única
   comprobación del bootloader del slot B: `fastboot getvar
   version-bootloader` (paso 5 y preflight de `flash-slot-b.sh`) solo informa
   del slot actual. Hazlo **antes** de flashear nada en el slot B (con Linux
   en B, ese slot ya no arranca Android); si no coinciden, no sigas.
5. **Comprobar ambos slots** en fastboot con `getvar current-slot`,
   `slot-successful:a`, `slot-successful:b`, `version-bootloader` y
   `version-baseband`. Nuestro resultado: ambos "successful", bootloader
   `ripcurrentpro-17.0-16433847`, baseband `g5400c-260818-261007-B-16536938`
   (`version-bootloader` es solo el del slot actual; que ambos lo lleven sale
   de las lecturas de `ro.bootloader` de los pasos 3 y 4).
   **El slot activo tiene que ser el A antes de seguir.** Todas las reglas del
   proyecto suponen Android stock activo y verificado en el slot A. El doble
   sideload deja el teléfono activo en el slot donde empezó, así que
   `current-slot` puede dar `b`; en ese caso, `fastboot --set-active=a`,
   arrancar Android del todo y verificarlo (`adb shell getprop
   ro.boot.slot_suffix` debe dar `_a`) antes del paso 6. Nuestra unidad
   estaba en el slot A. Con el bootloader aún **bloqueado**, `--set-active`
   puede ser rechazado (no verificado por nosotros); en ese caso, haz sideload
   del mismo OTA completo una vez más (cada sideload cambia el slot activo) y
   vuelve a comprobarlo, o desbloquea primero (paso 7) y cambia de slot
   después. Verificado en nuestra unidad: empezamos en el slot A, el primer
   sideload dejó activo el B y el segundo dejó activo el A. Comprueba también,
   tras el OTA y antes de desbloquear o flashear, que
   `fastboot getvar snapshot-update-status` da `none` (si no, arranca Android
   y deja que termine la actualización), y no uses
   `fastboot snapshot-update cancel` *(precaución no verificada en nuestra
   unidad)*.
6. **Preparar Android** en Opciones de desarrollador: activar **Desbloqueo de
   OEM** (en unidades bloqueadas por operadora aparece atenuado y no se puede
   activar; también puede seguir atenuado hasta que el teléfono se conecte a
   internet *(comportamiento estándar, no registrado literalmente en nuestra
   sesión)*) y **Depuración USB**, y **desactivar las actualizaciones
   automáticas del sistema**. Eso **no** basta: tampoco hay que aceptar
   manualmente ningún OTA, porque se escribiría en el slot inactivo, el B,
   reservado para Linux.
7. **Desbloquear (borra todos los datos):** `adb reboot bootloader` y
   `fastboot flashing unlock` (**borra todos los datos del teléfono**; haz
   copia antes); confirmar en el teléfono con volumen y encendido *(paso
   estándar, no registrado literalmente en nuestra sesión)*. Tras la
   configuración inicial, volver a activar la depuración USB para el paso 8 y
   a desactivar las actualizaciones automáticas siempre, a ser posible antes
   de conectar a internet (el borrado restablece el ajuste); seguir sin
   aceptar ningún OTA.
8. **Comprobar el resultado:** `adb shell getprop ro.boot.verifiedbootstate`
   debe dar `orange`. Nuestro estado final: slot activo A, ambos slots
   "successful".

### Lo que no hicimos

- Ni `flash-all.sh` ni `fastboot -w`.
- **Nunca ejecutes `fastboot flashing lock`** con imágenes no stock en algún
  slot: puede brickear el teléfono sin remedio, y volver a bloquear también
  borra los datos.
- No se flasheó a mano `bootloader`, `radio`, `vbmeta`, `devinfo`, `efs` ni
  `persist`.
- La copia privada de las particiones con IMEI/calibración **no** se hizo
  aquí: requiere root. Se hizo después desde el Linux en RAM del hito 1
  ([MILESTONE-1.md](MILESTONE-1.md)).
