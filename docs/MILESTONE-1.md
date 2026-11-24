# Milestone 1: RAM-only Linux on slot B / Hito 1: Linux solo en RAM en el slot B

Passed on our unit on 2026-11-24 (see [JOURNAL.md](JOURNAL.md)). This is a
high-level, reproducible description of what we did. It boots mainline-based
Linux from slot B entirely in RAM, with every UFS partition read-only and
nothing mounted, and keeps stock Android on slot A.

Superado en nuestra unidad el 2026-11-24 (ver [JOURNAL.md](JOURNAL.md)).
Descripción reproducible y a alto nivel de lo que hicimos: Linux (base
mainline) arranca desde el slot B solo en RAM, con todas las particiones UFS en
solo lectura y nada montado, y Android stock sigue en el slot A.

[English](#english) · [Español](#español)

---

## English

### Before you start

- Read [SAFETY.md](SAFETY.md) entirely. In particular:
  [flashing rules](SAFETY.md#flashing-rules--reglas-de-flasheo),
  [returning to stock](SAFETY.md#returning-to-stock--vuelta-a-stock) and
  [before every commit or push](SAFETY.md#before-every-commit-or-push--antes-de-cada-commit-o-push).
- Your phone must be in the state described in [UNLOCK.md](UNLOCK.md):
  bootloader unlocked, Android 17 `CP4A.261105.040.A1` on **both** slots,
  bootloader `ripcurrentpro-17.0-16433847`, **active slot A**, automatic
  updates disabled. The preflight (`flash-slot-b.sh --dry-run`) checks exactly
  this, and nothing more: exactly one fastboot device, with the serial you
  pass; `product` = `komodo`; `is-userspace` = `no` (bootloader, not
  fastbootd); `unlocked` = `yes`; `version-bootloader` =
  `ripcurrentpro-17.0-16433847`; `current-slot` = `a`;
  `slot-successful:a` = `yes`; `slot-unbootable:a` = `no`;
  `snapshot-update-status` = `none` (only if the bootloader has that
  variable); `partition-size` of the five `_b` partitions; and, for each of
  the five images, its SHA-256 against `SHA256SUMS`, its size, and an AVB
  footer with its partition name, `SHA256_RSA4096` and rollback index
  `1793836800`. It does **not** check the Android build on either slot nor the
  automatic-update setting.
- **It cannot check slot B's bootloader or Android build:
  `version-bootloader` only reports the current slot.** Before the first
  `set_active b`, verify yourself that BOTH slots carry the same bootloader
  (boot each slot once and read `ro.bootloader`, as the double sideload in
  [UNLOCK.md](UNLOCK.md#5-check-both-slots) does). Activating a slot with an
  older bootloader risks anti-rollback problems. This has to be done **before**
  flashing slot B: afterwards slot B no longer boots Android.
- **No warranty.** Flashing can leave the phone unbootable. We did this on one
  unit, once; your result may differ.
- Never flash `vbmeta`, anything on slot A, `bootloader`, `radio`, `devinfo`,
  `efs`, `persist`. Never `flash-all.sh`, never `fastboot -w`, never
  `fastboot flashing lock`.

### 1. Inputs

| Item | Value |
|---|---|
| Kernel | Omamobile fork [`linux-omarchy-mobile`](https://github.com/derekross/linux-omarchy-mobile), PR #276 (fork `oscarluke`, branch `omamobile-komodo-m1`), commit `ffd33b7ddc716eb3568fff9f8d337a4032d109eb` |
| Config | `defconfig` + Omamobile fragment `omamobile.config` |
| Toolchain | Android clang r596125, `LLVM=1`. `build-kernel.sh` checks the extracted tree's digest against the pin before building (`KOMODO_SKIP_TOOLCHAIN_CHECK=1` skips it explicitly); it checks the kernel commit only when the tree is a git checkout, and only warns for a `git archive` export |
| Resulting `uname -r` | `7.3.0-rc6-omamobile-push1` |
| Initramfs | Alpine minirootfs 3.24.2 aarch64 + dropbear, Omamobile `/init` (MIT) in `ram-rescue` mode |
| AVB key | AOSP public test key `testkey_rsa4096` |

All downloads, URLs and pinned hashes: [../scripts/README.md](../scripts/README.md).
None of the scripts downloads anything.

### 2. Build (host only, no phone)

```sh
export KOMODO_WORK=/path/to/your/private/workdir   # outside this repository
scripts/build-kernel.sh
scripts/mkinitramfs.sh
scripts/mkimages.sh
scripts/verify-images.sh        # must end with "Todo verificado (offline)."
```

#### Initramfs

`mkinitramfs.sh` unpacks the minirootfs and the three `.apk` files (their
install scripts are neither extracted nor run), prunes apk-tools and OpenSSL,
adds Omamobile's `/init` unchanged (its SHA-256 is pinned), the `ram-rescue`
mode files, compatible `google,zumapro-komodo`, and your SSH public key. It
deliberately has **no UFS write list**. Dropbear host keys are generated in RAM
on each boot, so the host key changes every boot.

We audited this `/init` before using it: in `ram-rescue` mode without a UFS
write list it does not write to block devices, does not mount partitions and
does not mark the slot as successful.

#### The five images

| Partition | Content |
|---|---|
| `boot_b` | header v4, kernel `Image.lz4`, no ramdisk, empty cmdline |
| `init_boot_b` | header v4, empty ramdisk, `os_version` 17.0.0, patch level 2026-11 |
| `vendor_boot_b` | header v4, page size 0x800, empty fragment, bring-up `vendor_cmdline` |
| `vendor_kernel_boot_b` | header v4, page size 0x800, DTB `zumapro-komodo`, lz4 initramfs (~1.5 MiB) |
| `dtbo_b` | one entry, id 0x60806 rev 0x10000 (empty overlay, [../device/komodo-board-overlay.dts](../device/komodo-board-overlay.dts)) |

Every image carries an **AVB hash footer**: `SHA256_RSA4096` with the AOSP test
key, rollback index `1793836800`, props `os_version` 17 and `security_patch`
2026-11-05, padded to the exact partition size. `vbmeta_b` stays **stock**.
With the bootloader unlocked, the ABL booted these images (verified on our
unit).

> **Build-specific values.** The rollback index, the `os_version`,
> `security_patch` and patch-level values, the dtbo id/rev, the partition
> sizes and the bootloader version pinned in the scripts are specific to build
> `CP4A.261105.040.A1` (= values from that build's stock vbmeta/footers). On
> any other build take them from the stock images actually installed; **never
> use a rollback index higher than stock.**

Bring-up `vendor_cmdline`:
`console=tty0 clk_ignore_unused pd_ignore_unused printk.devkmsg=on panic=10 bootconfig`.
On our unit the ABL **does** append it (see [DEVICE.md](DEVICE.md)).

### 3. Preflight and flash (slot B only)

Enter the bootloader (from Android: `adb reboot bootloader`; or hold
**Power + Volume Down**, verified on our unit). Then:

```sh
fastboot devices                                   # exactly one line
scripts/flash-slot-b.sh --dry-run <SERIAL>         # checks only, writes nothing
fastboot getvar slot-retry-count:b                 # note it
scripts/flash-slot-b.sh <SERIAL>                   # type FLASH-B; flashes the five _b
```

The preflight checks are the ones listed in
[Before you start](#before-you-start). Without `--dry-run`, the script also
recomputes each image's SHA-256 right before its `flash` and aborts if it
changed. Slot B's bootloader is **not** checked (see above).

Observed: flashing any `_b` partition set `slot-successful:b=no`.

### 4. Switch to B and boot (by hand)

**Before the first `set_active b`:** the scripts cannot check slot B's
bootloader (`version-bootloader` only reports the current slot). Make sure you
verified that both slots carry the same bootloader by reading `ro.bootloader`
on each slot (see [UNLOCK.md](UNLOCK.md#5-check-both-slots)); activating a
slot with an older bootloader risks anti-rollback problems.

```sh
fastboot -s <SERIAL> set_active b
fastboot -s <SERIAL> getvar slot-retry-count:b     # ours: 3
fastboot -s <SERIAL> reboot
```

Linux never marks slot B as successful, so every boot of B spends one retry.
With retries exhausted the bootloader goes back to slot A by itself (observed,
see step 7). How much of the counter a Linux **panic** consumes is not
verified.

### 5. What to expect

- Phone screen: **black** during the whole Linux boot (no framebuffer in this
  device tree). Do not wait for anything on screen.
- Host: USB gadget `1d6b:0104` (NCM + ACM) enumerated about **24 s** after the
  reboot on our unit. A serial console appears on the ACM port (a root shell,
  no password) and a `cdc_ncm` network interface.
- Network: the phone is `172.16.42.1/24`, no DHCP. Give the host
  `172.16.42.2/24` on the new interface, then
  `ssh -i <your-key> root@172.16.42.1`. The host key changes every boot.
- **Subnet clash:** `172.16.42.0/24` is also the default USB network of other
  postmarketOS phones. If one is connected to the same PC, the routes clash. We
  solved it by adding a second address in another subnet to the phone's `usb0`
  from the serial console (RAM only, lost on reboot), e.g.
  `ip addr add <other-subnet-address>/24 dev usb0`, and the matching address on
  the host.
- If no host configures the gadget within 45 s, Omamobile's `/init` panics on
  purpose and the phone reboots (`panic=10`); enumeration alone cancels that.
  *(From reading the init script, not observed.)*

Read-only checks we ran inside the phone:

```sh
uname -r                                  # 7.3.0-rc6-omamobile-push1
grep slot_suffix /proc/bootconfig         # "_b"
grep -H . /sys/block/sd*/sd*/ro           # all 1 (62 partitions on our unit)
mount                                     # no UFS partition mounted
dmesg | grep -i watchdog                  # "watchdog inactive, reset disabled" (x2)
```

If any partition shows `ro` = 0, stop and go back to A (step 7). Our result:
62 partitions, all read-only, none mounted; ~15.5 GiB `MemTotal`; clock
running normally; stable for more than 7 minutes until we forced it off. Only
dmesg warnings: undescribed UFS regulators and
`cpufreq-dt: deferred probe pending`.

### 6. Private backup (read-only, hash on both ends)

From that Linux, over SSH, we copied every partition except `userdata` and
`super` (60 partitions, ~1.5 GiB) to a **private** directory outside this
repository, one at a time, computing SHA-256 on the phone
(`sha256sum /dev/<dev>`) and on the host, and comparing both. Find each
partition's device by its `PARTNAME=` in `/sys/class/block/*/uevent`. Copy the
identity/calibration partitions first: `efs`, `efs_backup`, `modem_userdata`,
`persist`, `devinfo`, `mfg_data`. In practice we copy everything except
`userdata` and `super`. Confirm all `ro` flags are 1 before starting.

These copies contain IMEI, keys and calibration. **Never** put them, their
names with unit data, or their hashes in this repository, an issue or a log.

We also checked that `boot_a` was identical to the stock factory image and
`boot_b` identical to our built image.

### 7. Back to Android on slot A

1. Hold **Power + Volume Down** until the bootloader appears (verified on
   `komodo`, our unit).
2. `fastboot getvar current-slot`. In our case the bootloader had **already**
   returned to `a` by itself, with `slot-retry-count:b` at 0: the forced
   reboots had used up the retries.
3. Run `fastboot -s <SERIAL> set_active a` anyway, then
   `fastboot -s <SERIAL> reboot`.

Android booted on A with its data intact (USB debugging still authorized,
automatic updates still disabled). Optionally, from the bootloader with A
active: `scripts/restore-slot-b-stock.sh --dry-run <SERIAL>` and then without
`--dry-run` to put the five `_b` boot partitions back to stock.

To repeat the milestone: `set_active b` again (it reloads the retries:
*expected, not verified by us*). The same warning applies: both slots must
carry the same bootloader.

### Not verified

- Whether a Linux panic consumes retries, and how many.
- That a second `set_active b` reloads the retries (expected).
- The automatic panic 45 s after boot without a configured gadget (read in the
  init script, never triggered by us).
- Display/framebuffer (none in this tree).
- Any hardware beyond read-only UFS, USB gadget, RAM and CPU.
- Buttons under Linux.

---

## Español

### Antes de empezar

- Lee [SAFETY.md](SAFETY.md) entero, en especial las
  [reglas de flasheo](SAFETY.md#flashing-rules--reglas-de-flasheo), la
  [vuelta a stock](SAFETY.md#returning-to-stock--vuelta-a-stock) y la
  [lista antes de cada commit](SAFETY.md#before-every-commit-or-push--antes-de-cada-commit-o-push).
- El teléfono debe estar como describe [UNLOCK.md](UNLOCK.md): bootloader
  desbloqueado, Android 17 `CP4A.261105.040.A1` en **ambos** slots,
  bootloader `ripcurrentpro-17.0-16433847`, **slot activo A**,
  actualizaciones automáticas desactivadas. El preflight
  (`flash-slot-b.sh --dry-run`) comprueba exactamente esto y nada más: un
  único dispositivo fastboot, con la serie que pasas; `product` = `komodo`;
  `is-userspace` = `no` (bootloader, no fastbootd); `unlocked` = `yes`;
  `version-bootloader` = `ripcurrentpro-17.0-16433847`; `current-slot` = `a`;
  `slot-successful:a` = `yes`; `slot-unbootable:a` = `no`;
  `snapshot-update-status` = `none` (solo si el bootloader tiene esa
  variable); el `partition-size` de las cinco `_b`; y, de cada una de las
  cinco imágenes, su SHA-256 contra `SHA256SUMS`, su tamaño y un pie AVB con
  su nombre de partición, `SHA256_RSA4096` y rollback index `1793836800`.
  **No** comprueba el build de Android de ningún slot ni el ajuste de
  actualizaciones automáticas.
- **No puede comprobar el bootloader ni el build de Android del slot B:
  `version-bootloader` solo informa del slot actual.** Antes del primer
  `set_active b`, verifica tú que AMBOS slots llevan el mismo bootloader
  (arranca cada slot una vez y lee `ro.bootloader`, como hace el doble
  sideload de [UNLOCK.md](UNLOCK.md#pasos)). Activar un slot con un bootloader
  más antiguo arriesga problemas de anti-rollback. Hay que hacerlo **antes**
  de flashear el slot B: después, el slot B ya no arranca Android.
- **Sin garantía.** Lo hicimos en una unidad, una vez.
- Nunca flashees `vbmeta`, nada del slot A, `bootloader`, `radio`, `devinfo`,
  `efs` ni `persist`; nunca `flash-all.sh`, `-w` ni `flashing lock`.

### Resumen de pasos

Los comandos son los de la sección inglesa.

1. **Entradas:** kernel del fork de Omamobile (PR #276, commit
   `ffd33b7ddc716eb3568fff9f8d337a4032d109eb`), `defconfig` + `omamobile.config`,
   clang de Android r596125 con `LLVM=1` (`build-kernel.sh` comprueba el
   digest del árbol de clang contra el pin antes de compilar, salvo con
   `KOMODO_SKIP_TOOLCHAIN_CHECK=1`, y el commit del kernel solo si el árbol es
   un checkout git; con un `git archive` solo avisa); initramfs con Alpine minirootfs
   3.24.2 + dropbear y el `/init` de Omamobile (MIT) en modo `ram-rescue`.
   Descargas y hashes en [../scripts/README.md](../scripts/README.md); los
   scripts no descargan nada.
2. **Build en el PC:** `KOMODO_WORK` apuntando a un directorio privado fuera
   del repo; `build-kernel.sh`, `mkinitramfs.sh`, `mkimages.sh`,
   `verify-images.sh`. Las cinco imágenes (`boot_b`, `init_boot_b`,
   `vendor_boot_b`, `vendor_kernel_boot_b`, `dtbo_b`) llevan pie AVB hash
   `SHA256_RSA4096` con la clave de prueba pública de AOSP, rollback index
   `1793836800`, props `os_version` 17 y `security_patch` 2026-11-05, y miden
   lo mismo que la partición. `vbmeta_b` se queda **stock**; con el bootloader
   desbloqueado el ABL las arrancó (verificado). El `/init` se auditó antes:
   en ese modo no escribe en dispositivos de bloque, no monta particiones y no
   marca el slot como correcto. **Valores específicos del build:** el
   rollback index, `os_version`, `security_patch`, el nivel de parche, el
   id/rev del dtbo, los tamaños de partición y la versión del bootloader
   fijados en los scripts son específicos del build `CP4A.261105.040.A1` (=
   valores del vbmeta y los pies stock de ese build). Con cualquier otro
   build, tómalos de las imágenes stock realmente instaladas; **nunca uses un
   rollback index mayor que el de stock.**
3. **Preflight y flash solo `_b`:** `flash-slot-b.sh --dry-run <SERIE>` y
   luego sin `--dry-run` (pide teclear `FLASH-B`; recalcula el SHA-256 de
   cada imagen justo antes de su `flash` y aborta si cambió). Observado:
   flashear cualquier `_b` pone `slot-successful:b=no`.
4. **Cambiar a B a mano:** antes del primer `set_active b`, asegúrate de que
   verificaste que ambos slots llevan el mismo bootloader leyendo
   `ro.bootloader` en cada uno (los scripts no pueden comprobar el del slot
   B; un bootloader más antiguo arriesga problemas de anti-rollback). Luego
   `set_active b` (nos dio 3 intentos) y `reboot`.
   Linux nunca marca el slot B como correcto: cada arranque gasta un intento.
5. **Qué esperar:** pantalla **negra** todo el rato; el gadget USB `1d6b:0104`
   (NCM + ACM) apareció en el PC a los ~24 s; consola serie por ACM (shell root
   sin contraseña) y SSH a `172.16.42.1` (PC en `172.16.42.2/24`, sin DHCP).
   **Choque de subred:** `172.16.42.0/24` es también la red USB por defecto de
   otros teléfonos con postmarketOS; si hay otro conectado al mismo PC, lo
   resolvimos añadiendo al `usb0` del teléfono (solo en RAM) una segunda IP en
   otra subred desde la consola serie. Comprobaciones en solo lectura: 62
   particiones, todas `ro`, ninguna montada; `slot_suffix` `_b`; ~15,5 GiB de
   RAM; watchdogs inactivos; estable más de 7 minutos. Si ningún PC configura
   el gadget en 45 s, el `/init` de Omamobile provoca un pánico y el teléfono
   se reinicia *(según la lectura del script de init, no observado)*.
6. **Copia de seguridad privada:** por SSH, en solo lectura, todas las
   particiones salvo `userdata` y `super` (60, ~1,5 GiB), una a una y con
   SHA-256 en los dos extremos; primero las de identidad/calibración: `efs`,
   `efs_backup`, `modem_userdata`, `persist`, `devinfo`, `mfg_data`. Contienen IMEI, claves y calibración:
   **nunca** al repositorio.
7. **Vuelta a A:** **Encendido + Volumen −** lleva a fastboot (verificado). El
   bootloader ya había vuelto solo a `current-slot=a` con
   `slot-retry-count:b=0`; aun así, `set_active a` y `reboot`. Android arrancó
   con sus datos intactos. Opcional: `restore-slot-b-stock.sh` para devolver
   las cinco `_b` a stock. Para repetir el hito: `set_active b` otra vez
   (recarga los intentos: *esperado, no verificado por nosotros*), con la
   misma advertencia sobre el bootloader de ambos slots.

### Sin verificar

Si un pánico de Linux consume intentos y cuántos; que un segundo
`set_active b` recargue los intentos (esperado); el pánico automático a los
45 s sin gadget configurado (leído en el script de init, nunca provocado);
pantalla/framebuffer;
botones bajo Linux; todo el hardware salvo UFS en solo lectura, gadget USB,
RAM y CPU.
