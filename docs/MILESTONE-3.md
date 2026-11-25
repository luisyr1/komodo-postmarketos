# Milestone 3: Phosh on real KMS with the GPU, battery readout and reboot to the bootloader / Hito 3: Phosh sobre KMS real con GPU, lectura de batería y reinicio al bootloader

Reached on our unit on 2026-11-25 (see [JOURNAL.md](JOURNAL.md)). This is a
reproducible description of what we did on top of
[Milestone 2](MILESTONE-2.md): kernel package `linux-google-zumapro`
`pkgrel=2` (11 patches) and device package `device-google-komodo`
`pkgrel=3`, Nura reinstalled with the **Phosh** UI. The display moves from a
`simpledrm` console to real KMS (`gs-decon` stage 2) with brightness control,
the Mali-G715 GPU renders through Panthor and Mesa, the fuel gauge and the
charger are visible, and `reboot bootloader` reaches fastboot.

It is **not** a daily-driver phone: no WiFi, Bluetooth, audio, modem or
cameras; no managed USB-C; the slot B retry counter is still unresolved.
Everything was verified once, on one unit.

Alcanzado en nuestra unidad el 2026-11-25 (ver [JOURNAL.md](JOURNAL.md)).
Descripción reproducible de lo que hicimos sobre el [hito 2](MILESTONE-2.md):
paquete del kernel `linux-google-zumapro` `pkgrel=2` (11 parches) y paquete
del dispositivo `device-google-komodo` `pkgrel=3`, Nura reinstalado con la UI
**Phosh**. La pantalla pasa de consola `simpledrm` a KMS real (`gs-decon`
stage 2) con control de brillo, la GPU Mali-G715 renderiza con Panthor y
Mesa, el fuel gauge y el cargador se ven, y `reboot bootloader` llega a
fastboot.

**No** es un teléfono para el día a día: sin WiFi, Bluetooth, audio, módem ni
cámaras; sin USB-C gestionado; el contador de intentos del slot B sigue sin
resolver. Todo se comprobó una vez, en una unidad.

> **Irreversible: reinstalling flashes `userdata` again** and wipes the
> previous Nura install (and anything you kept on it). Keep a copy of what
> you need first.
>
> **Slot B retry counter: still unresolved.** Every boot of slot B spends one
> of its three retries (see [MILESTONE-2.md](MILESTONE-2.md)). `reboot
> bootloader` now gets you to fastboot without buttons, so reloading the
> counter with `fastboot set_active b` is easier, but you still have to do it.
>
> **GPU without a power domain driver.** G3D has no power domain driver in
> this kernel; it works because the bootloader leaves it powered. Panthor now
> loads automatically at boot (it was blacklisted at first). If a different
> bootloader stopped leaving G3D on, probing it could hang the SoC.
>
> **Reinstalar vuelve a flashear `userdata`** y borra la instalación anterior
> de Nura. **El contador del slot B sigue sin resolver.** **La GPU no tiene
> driver de power domain:** funciona porque el bootloader deja G3D encendido;
> Panthor se carga solo al arrancar.

[English](#english) · [Español](#español)

---

## English

### Before you start

- Everything in [MILESTONE-2.md](MILESTONE-2.md#before-you-start) applies,
  and Milestone 2 should already work on your unit: same separate pmbootstrap
  configuration, work directory and pmaports copy, same image script.
- **No warranty.** We did this on one unit, once.

### 1. Inputs

| Item | Value |
|---|---|
| pmbootstrap | 3.12.1, the same separate configuration as Milestone 2 |
| pmaports | channel **edge**, plus this repository's [`pmaports/device/testing/`](../pmaports/device/testing/) packages, refreshed: `device-google-komodo` `pkgrel=3`, `linux-google-zumapro` `pkgrel=2` |
| Kernel source | unchanged: `derekross/linux-omamobile` at commit `ffd33b7ddc716eb3568fff9f8d337a4032d109eb` (PR #276) |
| Kernel patches | 11 (table in step 2) |
| Kernel config | the Milestone 2 config plus `CONFIG_DRM_PANEL_GOOGLE_KM4=m` |
| Resulting `uname -r` | `7.3.0-rc6-zumapro` |
| UI / init | **phosh** (phoc compositor, greetd with the phrog greeter, stevia on-screen keyboard) / systemd |
| Extra packages | `linux-firmware-arm,mesa-dri-gallium,mesa-utils,kmscube` |
| GPU firmware | `arm/mali/arch11.8/mali_csffw.bin`, from Alpine's `linux-firmware-arm` package (not redistributed by this repository) |
| Mesa | 26.3.1 (Alpine edge) |
| Images | [`../scripts/mkimages-pmos.sh`](../scripts/mkimages-pmos.sh), unchanged |

### 2. What the packages change

Kernel patches (`linux-google-zumapro`, `pkgrel=2`):

| Patch | What it does | Status on our unit |
|---|---|---|
| 0001–0003 | "display A": `gs-decon` built in, `console=tty0` and fbcon font, `simple-framebuffer` on the bootloader framebuffer | in use; the `simple-framebuffer` stays as a fallback (see 0010) |
| 0004 | enables the Synaptics S3908 touchscreen | works (Phosh by touch) |
| 0005 | describes the MAX77779 fuel gauge (read-only driver) | works: percentage and design capacity |
| 0006 | describes the MAX77779 charger | detected (see step 8) |
| 0007 | enables `syscon-reboot-mode` (needs `reboot=warm`) | works: `reboot bootloader` |
| 0008 | minimal `google,km4` panel driver: brightness only, backlight range 0..3271 (0 = pixel off) | works: brightness control |
| 0009 | DSIM0 as a DCS command host for the KM4 panel | works (carries the brightness commands) |
| 0010 | `gs-decon`: keep komodo's boot framebuffer aperture (`hold_boot_fb`) | in use with stage 2 |
| 0011 | enables the Mali-G715 node, `cmu_g3d` and the 150/302 MHz OPP table | works with Panthor |

The commit messages of 0008–0011 still say "Not tested on hardware" or "Not
tested on this tree", and 0011 says the device package blacklists `panthor`.
They are kept as they were built (only the `From:` line of every patch was
normalised for publication, with the checksums in the APKBUILD updated); the
table above is the current state. The
same goes for a DTS comment inside patch 0011 that still describes `panthor`
as blacklisted: since device `pkgrel=3` it is not.

Device package (`device-google-komodo`, `pkgrel=3`):

- `kernel-cmdline.conf` adds `reboot=warm gs_decon.stage=2 gs_decon.fbdev=1
  gs_dsim_cmd.allow_tx=1`. The DTB bootargs from 0002/0003 still say
  `gs_decon.stage=1`; the ABL puts the DTB bootargs first and the
  `vendor_boot` cmdline after them, and on our unit the later `stage=2`
  is the one that takes effect.
- `deviceinfo_drm="true"` (it was `false` with `simpledrm` only).
- `google-komodo-modprobe.conf`: once blacklisted `panthor`; in `pkgrel=3` it
  only carries a comment, so `panthor` autoloads.
- `50-google-komodo-buttons.conf` (logind drop-in, systemd subpackage): long
  press of the power key powers off. It is meant for the console UIs; Phosh
  handles the key itself. Neither path has been checked on our unit.
- `komodo-boot-success` (+ `.service`, `.timer`) and `komodo-bootctl.c`: a
  tool to mark slot B successful in `devinfo`. **Not in use.** The timer is
  installed but not enabled, and `komodo-bootctl` is shipped as source only
  (it is not compiled in this `pkgrel`), so the wrapper cannot run as
  packaged. The write path has never been executed. `komodo-bootctl.c`
  carries its own `Apache-2.0` SPDX header (it follows Google's boot-control
  HAL and Omamobile's `omamobile-bootctl.c`).

### 3. Refresh the pmaports copy

Copy both package directories from this repository over the ones in your
separate pmaports copy (as in
[MILESTONE-2.md step 2](MILESTONE-2.md#2-separate-pmaports-copy)), deleting
files that are no longer there.

### 4. Configuration

Same separate configuration file. The lines that change:

```ini
ui = phosh
extra_packages = linux-firmware-arm,mesa-dri-gallium,mesa-utils,kmscube
```

### 5. Build, install and images

```sh
"${PMB[@]}" kconfig check linux-google-zumapro
"${PMB[@]}" build linux-google-zumapro
"${PMB[@]}" build device-google-komodo
"${PMB[@]}" install
"${PMB[@]}" export "$KOMODO_WORK/pmos/export"
KOMODO_WORK=$KOMODO_WORK scripts/mkimages-pmos.sh "$KOMODO_WORK/pmos/export"
```

No `KOMODO_EXTRA_CMDLINE` is needed: the display and reboot parameters come
from the device package through boot-deploy. Check that
`$KOMODO_WORK/build/images-pmos/cmdline.txt` contains `gs_decon.stage=2` and
`reboot=warm`.

### 6. Flash (irreversible for userdata) and boot

Exactly as [MILESTONE-2.md step 9](MILESTONE-2.md#9-flash-userdata-irreversible-and-boot):
`userdata` with the sparse image plus the five `_b` images, `set_active b`,
`reboot`. Slot A, the bootloader, radio and `vbmeta` are not touched.

### 7. First boot: disable buffyboard

On our install `buffyboard.service` (the on-screen keyboard of the text
console) was still enabled under Phosh. It received the same touches as
Phosh and injected key presses into the console, so phantom characters
appeared in the PIN field of the greeter. Over SSH:

```sh
sudo systemctl disable --now buffyboard
```

We have not found out yet what enables it on a Phosh install.

### 8. Checks we ran

Over SSH; all read-only:

```sh
uname -r                                   # 7.3.0-rc6-zumapro
systemctl --failed                         # ours: 0 units after a clean reboot
cat /proc/fb                               # expected: the gs-decon fbdev, not simpledrm
ls /sys/class/backlight/                   # the KM4 backlight
cat /sys/class/backlight/*/max_brightness  # 3271
ls /sys/class/power_supply/                # fuel gauge and charger
cat /sys/class/power_supply/*/capacity
lsmod | grep panthor                       # ours: loaded by itself, ~5 s into the boot
```

What we saw:

- **Display:** real KMS through `gs-decon` stage 2 at 60 Hz, Phosh on it.
  Brightness control works through the KM4 backlight device (range
  0..3271).
- **GPU:** Panthor bound the Mali-G715 and loaded the CSF firmware; Mesa
  26.3.1 reports "Mali-G715 MC7 (Panfrost)", OpenGL ES 3.1. Phosh's
  graphical login is GPU-accelerated. No performance measurements.
- **Touch and UI:** Phosh graphical login by touch (greetd + phrog, stevia
  keyboard), once `buffyboard` was disabled.
- **Battery:** the fuel gauge reports the charge percentage and a design
  capacity of 5035 mAh. The charger is detected. From a PC USB port the input
  is 500 mA: the battery holds its level and barely charges.
- **Reboot to the bootloader:** `sudo reboot bootloader` reaches fastboot
  without buttons and without spending an extra slot B retry.
- **System:** after a clean reboot, zero failed systemd units.

### 9. Updating the kernel without reinstalling

What we did to move between kernel builds without reflashing `userdata`:

1. Build the new `linux-google-zumapro` apk on the PC.
2. Copy the apk to the phone and install it there:
   `sudo apk add --allow-untrusted --no-network ./linux-google-zumapro-*.apk`
   (our own unsigned build; the phone has no network).
3. The phone regenerates its boot files (`vmlinuz`, `initramfs`,
   `vendor_boot.img` in `/boot`) through mkinitfs and boot-deploy.
4. Copy those three files back to the PC into a directory and run
   `scripts/mkimages-pmos.sh` on it (no `google-komodo.img` there, so no
   sparse image is made).
5. Flash only `boot_b`, `vendor_boot_b` and `vendor_kernel_boot_b`; leave
   `userdata`, `init_boot_b` and `dtbo_b` alone.

The same works for a new `device-google-komodo` apk when the change is in
the kernel command line.

### 10. Back out

- **Previous kernel:** reflash the previous `boot_b`, `vendor_boot_b` and
  `vendor_kernel_boot_b` (keep each image set with its `SHA256SUMS`), and
  downgrade the apk on the phone if you need the modules to match.
- **GPU off:** `echo 'blacklist panthor' | sudo tee /etc/modprobe.d/no-panthor.conf`
  and reboot; Phosh then falls back to software rendering (not tried by us).
- **Text console instead of KMS:** a `vendor_boot_b` without
  `gs_decon.stage=2 gs_decon.fbdev=1` falls back to `simpledrm` through the
  DTB's `stage=1` (not tried by us in this milestone).
- Everything in [MILESTONE-2.md step 12](MILESTONE-2.md#12-back-out) still
  applies.

### 11. What does not work yet

1. **WiFi and Bluetooth:** Broadcom BCM4390 combo; WiFi over PCIe (ID
   `14e4:4438`). Mainline `brcmfmac` does not support this chip, and the
   PCIe nodes stay disabled in our kernel. Its firmware is Google's and will
   not be shipped here.
2. **Audio, modem, cameras:** not started.
3. **Managed USB-C (TCPC):** a patch is prepared but not integrated. Without
   it there are no Type-C roles and no USB-PD, hence the 500 mA from a PC
   port.
4. **Slot B retry counter:** each boot spends 1 of 3; `fastboot set_active b`
   reloads it. The `komodo-bootctl` tool in the package is source only, not
   compiled and never used to write.
5. **Buttons:** no verified action for power or volume keys under Phosh.
6. **Power off:** not tested.
7. **USB enumeration `error -71`:** on some boots the PC fails to enumerate
   the phone's USB gadget with `error -71`. Intermittent, cause unknown.
8. **`buffyboard` under Phosh:** disabled by hand (step 7); the cause is not
   fixed in the packages.
9. **GPU:** only the 150/302 MHz levels, no thermal limits for it, no power
   domain driver, no suspend; no performance numbers.
10. **Display:** 60 Hz only, no 120 Hz; no real panel sleep (no DCS
    display-off/sleep-in sequence wired to a KMS output port).
11. **Battery:** no charge control policy, no thermal bands, no measured
    behaviour with a fast charger; the shunt value comes from the Pixel 9a
    reference and has only been checked against the design capacity.

### Not verified

- Suspend/resume of anything (display, touch, GPU, USB).
- The phone's behaviour when the battery runs out under Linux.
- Charging from a wall charger or with USB-PD.
- Whether the stage 2 KMS code in our tree is exactly what third parties
  tested on `komodo` (they used a local integration build).
- What enables `buffyboard.service` on a Phosh install.
- Any hardware beyond what is listed in [STATUS.md](STATUS.md).

---

## Español

### Antes de empezar

Vale todo lo de [MILESTONE-2.md](MILESTONE-2.md#antes-de-empezar) y el hito 2
debe funcionar ya en tu unidad. **Sin garantía:** lo hicimos una vez, en una
unidad.

### Resumen de pasos

Los comandos son los de la sección inglesa.

1. **Entradas:** la misma configuración aparte de pmbootstrap 3.12.1, canal
   edge; paquetes de este repo actualizados: `device-google-komodo`
   `pkgrel=3` y `linux-google-zumapro` `pkgrel=2` (mismo commit `ffd33b7…`,
   11 parches, config del hito 2 más `CONFIG_DRM_PANEL_GOOGLE_KM4=m`). UI
   **phosh** (phoc, greetd con phrog, teclado stevia), systemd; paquetes
   extra `linux-firmware-arm,mesa-dri-gallium,mesa-utils,kmscube`. Firmware
   de la GPU `arm/mali/arch11.8/mali_csffw.bin` del paquete
   `linux-firmware-arm` de Alpine (no lo redistribuye este repo). Mesa 26.3.1.
2. **Qué cambian los paquetes:** 0001–0003 "display A"; 0004 táctil; 0005
   fuel gauge MAX77779 (solo lectura); 0006 cargador MAX77779; 0007
   `syscon-reboot-mode`; 0008 driver mínimo del panel KM4 (solo brillo,
   rango 0..3271, 0 = píxel apagado); 0009 DSIM0 como host DCS para el
   panel; 0010 `gs-decon` retiene la apertura del framebuffer de arranque;
   0011 Mali-G715 (nodo `gpu`, `cmu_g3d`, OPP 150/302 MHz). Los mensajes de
   0008–0011 siguen diciendo "Not tested on hardware" o "Not tested on this
   tree", y el 0011 dice que el paquete del dispositivo pone `panthor` en
   lista negra: se conservan como se compilaron; el estado real es el de la
   tabla inglesa. Lo mismo con un comentario del DTS dentro del parche 0011. El paquete
   del dispositivo añade a la cmdline `reboot=warm gs_decon.stage=2
   gs_decon.fbdev=1 gs_dsim_cmd.allow_tx=1` (el `stage=1` de los bootargs del
   DTB va antes y en nuestra unidad manda el `stage=2` posterior), pone
   `deviceinfo_drm="true"`, ya no pone `panthor` en lista negra, trae un
   drop-in de logind (pulsación larga = apagar, pensado para las UI de
   consola; sin comprobar) y la herramienta `komodo-boot-success` /
   `komodo-bootctl` para marcar el slot B, **sin usar**: el temporizador no
   está activado y `komodo-bootctl` va solo como fuente, sin compilar, así
   que el envoltorio no funciona tal cual; la escritura nunca se ha
   ejecutado. `komodo-bootctl.c` lleva su propia cabecera SPDX `Apache-2.0`.
3. **Copia de pmaports:** copiar encima los dos paquetes de este repo,
   borrando los ficheros que ya no existan.
4. **Configuración:** `ui = phosh` y los paquetes extra.
5. **Compilar, instalar e imágenes:** `kconfig check`, `build` de los dos
   paquetes, `install`, `export` y `scripts/mkimages-pmos.sh`. No hace falta
   `KOMODO_EXTRA_CMDLINE`; comprueba que `cmdline.txt` lleva
   `gs_decon.stage=2` y `reboot=warm`.
6. **Flashear y arrancar:** igual que el paso 9 del hito 2 (`userdata`,
   **irreversible**, y las cinco `_b`).
7. **Primer arranque, desactivar buffyboard:** `buffyboard.service` (el
   teclado en pantalla de la consola) seguía activo bajo Phosh, recibía los
   mismos toques e inyectaba teclas en la consola: caracteres fantasma en el
   PIN del greeter. Solución: `sudo systemctl disable --now buffyboard`.
   Pendiente: averiguar qué lo habilita en una instalación con Phosh.
8. **Comprobaciones:** KMS real con `gs-decon` stage 2 a 60 Hz y Phosh
   encima; el control de brillo funciona con el dispositivo de backlight del
   KM4 (rango 0..3271). Panthor enlaza la Mali-G715 y carga el firmware
   CSF; Mesa 26.3.1 la presenta como "Mali-G715 MC7 (Panfrost)", OpenGL
   ES 3.1; el login gráfico de Phosh va acelerado por GPU; Panthor se carga
   solo a los ~5 s del arranque. Sin medidas de rendimiento. Login gráfico
   tocando (greetd + phrog, teclado stevia). El fuel gauge da el porcentaje
   y una capacidad de diseño de 5035 mAh; el cargador se detecta; desde un
   puerto USB de PC la entrada es de 500 mA: mantiene la carga, casi no
   carga. `sudo reboot bootloader` llega a fastboot sin botones y sin gastar
   un intento extra del slot B. Tras un reinicio limpio, cero unidades de
   systemd fallidas.
9. **Actualizar el kernel sin reinstalar:** compilar el apk en el PC,
   copiarlo al teléfono, `sudo apk add --allow-untrusted --no-network
   ./linux-google-zumapro-*.apk` (build propio sin firmar; el teléfono no
   tiene red); el teléfono regenera `vmlinuz`, `initramfs` y
   `vendor_boot.img` en `/boot`; se copian al PC, se pasa ese directorio a
   `scripts/mkimages-pmos.sh` y se flashean solo `boot_b`, `vendor_boot_b` y
   `vendor_kernel_boot_b`. `userdata`, `init_boot_b` y `dtbo_b` no se tocan.
10. **Vuelta atrás:** reflashear las tres imágenes anteriores (guarda cada
    juego con su `SHA256SUMS`); GPU fuera con `blacklist panthor` en
    `/etc/modprobe.d/` (sin probar); consola de texto con una `vendor_boot_b`
    sin `gs_decon.stage=2 gs_decon.fbdev=1` (sin probar en este hito); el
    resto, como en el paso 12 del hito 2.
11. **Lo que aún no funciona:** WiFi y Bluetooth (combo Broadcom BCM4390,
    WiFi por PCIe con ID `14e4:4438`; el `brcmfmac` de mainline no lo
    soporta y los nodos PCIe siguen desactivados; su firmware es de Google y
    no se redistribuye); audio, módem y cámaras sin empezar; USB-C
    gestionado (TCPC) con un parche preparado pero no integrado, sin roles
    ni USB-PD (de ahí los 500 mA); contador del slot B (cada arranque gasta
    1 de 3; `fastboot set_active b` lo recarga; `komodo-bootctl` solo como
    fuente, sin compilar, nunca usado para escribir); botones sin acción
    comprobada bajo Phosh; apagado sin probar; fallo intermitente de
    enumeración USB `error -71` en algunos arranques, causa desconocida;
    `buffyboard` bajo Phosh desactivado a mano, sin arreglar en los
    paquetes; GPU solo a 150/302 MHz, sin límites térmicos, sin driver de
    power domain, sin suspensión ni medidas; pantalla solo a 60 Hz, sin
    120 Hz ni reposo real del panel; batería sin política de carga, sin
    bandas térmicas, sin prueba con cargador rápido, y el valor del shunt
    viene de la referencia del Pixel 9a y solo se ha contrastado con la
    capacidad de diseño.

### Sin verificar

Suspensión y reanudación de cualquier cosa; qué pasa al agotarse la batería
bajo Linux; carga con cargador de pared o con USB-PD; que el código KMS de
stage 2 de nuestro árbol sea exactamente el que probaron terceros en
`komodo` (usaron un build local de integración); qué habilita
`buffyboard.service` con Phosh; el resto del hardware
([STATUS.md](STATUS.md)).
