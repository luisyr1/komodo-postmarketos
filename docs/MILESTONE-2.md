# Milestone 2: Nura on userdata, booted from slot B / Hito 2: Nura en userdata, arrancado desde el slot B

Passed on our unit on 2026-11-25 (see [JOURNAL.md](JOURNAL.md)). This is a
reproducible description of what we did: Nura (edge, console UI, systemd)
built with pmbootstrap, its root filesystem written to `userdata`, and booted
by the ABL from slot B with the same five-image layout as
[Milestone 1](MILESTONE-1.md). Stock Android stays on slot A, but **its data
is gone**.

Superado en nuestra unidad el 2026-11-25 (ver [JOURNAL.md](JOURNAL.md)).
Descripción reproducible de lo que hicimos: Nura (edge, UI console, systemd)
construido con pmbootstrap, su raíz escrita en `userdata` y arrancado por el
ABL desde el slot B con la misma disposición de cinco imágenes que el
[hito 1](MILESTONE-1.md). Android stock sigue en el slot A, pero **sus datos
se pierden**.

> **Irreversible: flashing `userdata` destroys all Android data on the phone.**
> There is only one `userdata`, shared by both slots. Back up anything you
> care about first; it cannot be recovered afterwards.
>
> **Slot B retry counter: unresolved.** Every boot of slot B spends one of its
> three retries and nothing marks the slot as successful. When they run out,
> the ABL boots slot A (Android) instead. Third parties report that Android
> then reformats `userdata` (not verified by us), which would wipe the Nura
> install. Run `fastboot set_active b` before the retries run out (step 11).
>
> **Irreversible: flashear `userdata` destruye todos los datos de Android.**
> Solo hay un `userdata`, compartido por los dos slots. Haz copia antes.
>
> **Contador de intentos del slot B: sin resolver.** Cada arranque de B gasta
> uno de sus tres intentos y nada marca el slot como correcto; al agotarse, el
> ABL arranca el slot A (Android). Según terceros, Android reformatea entonces
> `userdata` (no verificado por nosotros) y se perdería Nura. Haz
> `fastboot set_active b` antes de que se agoten (paso 11).

[English](#english) · [Español](#español)

---

## English

### Before you start

- Everything in [MILESTONE-1.md](MILESTONE-1.md#before-you-start) applies:
  read [SAFETY.md](SAFETY.md), same stock build on both slots, active slot A,
  never touch `vbmeta*`, slot A, `bootloader`, `radio`, `devinfo`, `misc`,
  `efs`, `persist`; never `flash-all.sh`, never `fastboot flashing lock`.
- Do Milestone 1 first, including the **private backup of the partitions**
  (step 6 there). This milestone writes `userdata`; everything else stays
  read-only, but a backup is your only way back if something goes wrong.
- **Back up your Android data.** It will be lost in step 9.
- Battery above 50 %, USB cable straight to the PC (no hub).
- **No warranty.** We did this on one unit, once.

### 1. Inputs

| Item | Value |
|---|---|
| pmbootstrap | 3.12.1, with its **own** configuration file, work directory and pmaports copy (it never touches your default `pmbootstrap_v3.cfg`) |
| pmaports | channel **edge**, plus this repository's [`pmaports/device/testing/`](../pmaports/device/testing/) packages `device-google-komodo` and `linux-google-zumapro` |
| Kernel source | GitHub tarball of `derekross/linux-omamobile` (formerly `linux-omarchy-mobile`; the old URL redirects) at commit `ffd33b7ddc716eb3568fff9f8d337a4032d109eb` (PR #276), plus three "display A" patches. The tarball unpacks to `linux-omamobile-<commit>` and was checked file by file to be identical to the Milestone 1 tree |
| Kernel config | the RAM-only "display A" `.config` plus the options pmbootstrap's `kconfigcheck.toml` asks for (every category of the `community` alias except `hardening`), resolved with `make olddefconfig` |
| Toolchain | Alpine's clang inside pmbootstrap (not the Android clang of Milestone 1) |
| Resulting `uname -r` | `7.3.0-rc6-zumapro` |
| UI / init | `console` / systemd |
| Images | [`../scripts/mkimages-pmos.sh`](../scripts/mkimages-pmos.sh), AOSP test key, same AVB values as Milestone 1 |

Note: some comments inside the package files mention `hito2/PLAN.md`; that is
the owner's private working plan. This document is its public equivalent. The
package files are published byte-identical to the ones we built, except the
`Date:` lines of the three kernel patches, normalised to UTC (their checksums
in the APKBUILD were updated accordingly).

### 2. Separate pmaports copy

All paths below are examples under your private work directory, outside this
repository.

```sh
export KOMODO_WORK=/path/to/your/private/workdir
REPO=/path/to/this/repository
A=$KOMODO_WORK/pmos/pmaports
git clone https://gitlab.postmarketos.org/postmarketOS/pmaports.git "$A"     # [network]
cp -r "$REPO/pmaports/device/testing/device-google-komodo" \
      "$REPO/pmaports/device/testing/linux-google-zumapro" "$A/device/testing/"
git -C "$A" add device/testing && git -C "$A" commit -qm "komodo (local)"   # optional
```

pmbootstrap identifies the channel from a git remote pointing at the official
pmaports URL, so keep `origin` on it. If you start from an existing local
pmaports clone, clone that and run `git remote set-url origin <official URL>`.

### 3. Separate configuration

```sh
CFG=$KOMODO_WORK/pmos/pmbootstrap-komodo.cfg
PMB=(pmbootstrap -c "$CFG" -w "$KOMODO_WORK/pmos/work" -p "$A")
"${PMB[@]}" init                     # asks for sudo; creates the work dir
"${PMB[@]}" config device            # must print google-komodo
```

`init` (re)writes the file given with `-c`, never your default configuration.
Our answers: channel **edge**; vendor `google`, device `komodo` (found in
`device/testing`); a user name of your choice; UI **console**; systemd (the
edge default); no extra packages; a hostname of your choice; SSH keys **yes**.

We did not publish our configuration file (it holds private paths). Its
relevant lines, with neutral placeholders:

```ini
[pmbootstrap]
aports = <KOMODO_WORK>/pmos/pmaports
work = <KOMODO_WORK>/pmos/work
device = google-komodo
ui = console
service_manager = systemd
extra_packages = none
locale = C.UTF-8            # example
timezone = UTC              # example
ssh_keys = True
ssh_key_glob = <path to the ONE public key you want on the phone>
```

Restrict `ssh_key_glob` to a single dedicated public key; the default glob
copies every `~/.ssh/id_*.pub`. Never put the user password on a command line
(`--password` stays in your shell history).

Why console: there is no GPU, the screen is `simpledrm` on the bootloader's
framebuffer, and there is no touch input. A graphical UI adds failures you
cannot diagnose, and every failed boot spends a slot B retry.

### 4. Kernel tarball checksum and content check

The published `APKBUILD` already carries the real `sha512` of the tarball
(computed with `pmbootstrap checksum` on 2026-11-25) and
`builddir="$srcdir/linux-omamobile-$_commit"`. pmbootstrap verifies the
checksum when it fetches the tarball. Recompute it only if you change the
source:

```sh
"${PMB[@]}" checksum linux-google-zumapro          # downloads the tarball
```

We also compared the tarball with the Milestone 1 tree, file by file:

```sh
D=$KOMODO_WORK/pmos/work/cache_distfiles
C=ffd33b7ddc716eb3568fff9f8d337a4032d109eb
mkdir -p "$KOMODO_WORK/check/gh"
tar -xzf "$D/linux-google-zumapro-$C.tar.gz" -C "$KOMODO_WORK/check/gh"
diff -r "$KOMODO_WORK/check/gh/linux-omamobile-$C" "$KOMODO_WORK/src/linux-ffd33b7" && echo IDENTICAL
```

If `diff` reports anything, **stop**: the tarball is not the tree tested in
Milestone 1. Commit `ffd33b7` only lives at the head of PR #276; if GitHub
stops serving it, the way out is a fork or tag of your own and a new `source=`.

### 5. Build

```sh
"${PMB[@]}" kconfig check linux-google-zumapro      # passed on our host
"${PMB[@]}" build linux-google-zumapro              # ~21 min with 16 threads on our host
"${PMB[@]}" build device-google-komodo
```

### 6. Install and export

```sh
"${PMB[@]}" install                     # asks for the phone user's password
"${PMB[@]}" export "$KOMODO_WORK/pmos/export"
ls -l "$KOMODO_WORK/pmos/export"        # vmlinuz, initramfs, vendor_boot.img, boot.img, google-komodo.img
```

Do not use `--split`, `--sdcard` or `--android-recovery-zip`: the initramfs
expects **one** image with two partitions (`pmOS_boot`, `pmOS_root`, 4096-byte
sectors) inside `userdata`. `pmbootstrap export` only creates symlinks into
the pmbootstrap work directory.

### 7. Build the slot B images and the userdata image (host only)

```sh
KOMODO_WORK=$KOMODO_WORK scripts/mkimages-pmos.sh "$KOMODO_WORK/pmos/export"
# to debug the first boot (initramfs telnet shell):
#   KOMODO_EXTRA_CMDLINE="pmos.debug-shell" scripts/mkimages-pmos.sh ...
cat "$KOMODO_WORK/build/images-pmos/BUILDINFO"
```

Output in `$KOMODO_WORK/build/images-pmos/`: `boot.img`, `init_boot.img`,
`vendor_boot.img`, `vendor_kernel_boot.img`, `dtbo.img`,
`google-komodo-sparse.img`, `SHA256SUMS`, `BUILDINFO` and `cmdline.txt`. The
cmdline should contain `pmos_root_uuid=`. Keep the raw
`google-komodo.img` from the pmbootstrap work directory: it is your backup of
the root filesystem.

| Partition | Content |
|---|---|
| `boot_b` | header v4, `vmlinuz` (`Image.lz4`, lz4 legacy) from `linux-google-zumapro`, empty cmdline |
| `init_boot_b` | header v4, empty ramdisk, `os_version` 17.0.0, patch level 2026-11 |
| `vendor_boot_b` | header v4, page size 0x800, `vendor_cmdline` = the one boot-deploy computed (from the `vendor_boot.img` it generated), empty fragment |
| `vendor_kernel_boot_b` | header v4, page size 0x800, the package's DTB, the **Nura initramfs** as fragment |
| `dtbo_b` | empty overlay, id 0x60806 rev 0x10000 |

boot-deploy's own `boot.img`/`vendor_boot.img` are **not** flashed as they are:
the ABL is known to boot the Milestone 1 layout (DTB and ramdisk in
`vendor_kernel_boot`), and every failed experiment spends a retry. mkinitfs
produces a zstd initramfs (15 MB in our build); the script recompresses it to
lz4 legacy, the format that booted in Milestone 1
(`KOMODO_INITRAMFS_FORMAT=keep` leaves it as is; untested). It also checks
the image's GPT (4096-byte sectors, exactly `pmOS_boot` + `pmOS_root`, ext*),
that it fits in `userdata`, and that the sparse image converts back
identically.

`deviceinfo_flash_method="none"` on purpose: `pmbootstrap flasher` would write
`boot`/`vendor_boot` of the **active** slot (A, Android) with images the ABL
does not boot that way. Flashing is by hand. `scripts/flash-slot-b.sh` was not
used for this milestone.

### 8. Rehearsal without userdata (recommended)

Flash only the five `_b` images, leaving `userdata` (Android) alone:

```sh
O=$KOMODO_WORK/build/images-pmos
fastboot devices                                         # exactly one
fastboot -s <SERIAL> getvar product                      # komodo
fastboot -s <SERIAL> getvar unlocked                     # yes
fastboot -s <SERIAL> getvar current-slot                 # a
(cd "$O" && sha256sum -c SHA256SUMS)
for p in boot init_boot vendor_boot vendor_kernel_boot dtbo; do
  fastboot -s <SERIAL> flash "${p}_b" "$O/$p.img"
done
fastboot -s <SERIAL> set_active b
fastboot -s <SERIAL> reboot
```

What happened on our unit (with the initramfs at 15 MB zstd recompressed to
lz4 legacy): the ABL accepted the images, the USB gadget appeared after
~28 s, `ping 172.16.43.1` answered, and the initramfs dropped to its debug
shell because it found no root filesystem. That is the expected result: it
proves kernel, DTB, initramfs and USB network without writing anything.
Android's `userdata` stayed intact: once slot B ran out of boot attempts the
bootloader fell back to slot A and Android booted normally.

### 9. Flash userdata (irreversible) and boot

From the bootloader (`is-logical:userdata` is `no`, so it is flashed from the
bootloader, not fastbootd):

```sh
O=$KOMODO_WORK/build/images-pmos   # same directory as in step 8
fastboot devices                                         # exactly one
fastboot -s <SERIAL> getvar product                      # komodo
fastboot -s <SERIAL> getvar unlocked                     # yes
(cd "$O" && sha256sum -c SHA256SUMS)
fastboot -s <SERIAL> getvar is-logical:userdata          # no
fastboot -s <SERIAL> flash userdata "$O/google-komodo-sparse.img"   # IRREVERSIBLE: Android data lost
# the five _b images, if they are not there yet from step 8:
# for p in boot init_boot vendor_boot vendor_kernel_boot dtbo; do fastboot -s <SERIAL> flash "${p}_b" "$O/$p.img"; done
fastboot -s <SERIAL> set_active b
fastboot -s <SERIAL> getvar slot-retry-count:b           # note it (3)
fastboot -s <SERIAL> reboot
```

On our unit the sparse image was 834 MB; fastboot split it into 4 chunks and
the flash took ~23 s. We flashed `userdata` after the rehearsal, with the five
`_b` images already in place. Never use `flash boot` without `_b`, never
`flashall`, never `-w` here. Never touch `vbmeta*`, `misc` or `devinfo`.

### 10. Host network (do this before booting)

The installed system uses `172.16.43.0/24` (phone `.1`, PC `.2`; set in the
package's `/etc/unudhcpd.conf`, so it does not clash with other
postmarketOS phones on `172.16.42.0/24`). The PC side of the USB link has a
fixed, made-up MAC from `deviceinfo`, `02:6b:6f:6d:6f:01`.

The interface **re-enumerates** on every boot and every gadget change, and a
static address added by hand with `ip addr` is lost each time. What looked
like "USB dropping" several times was this, on the PC side. A NetworkManager
profile matched by that MAC, with autoconnect, fixes it:

```sh
nmcli connection add type ethernet con-name komodo-nura ifname '*' \
  ethernet.mac-address 02:6b:6f:6d:6f:01 \
  ipv4.method manual ipv4.addresses 172.16.43.2/24 ipv4.never-default yes \
  ipv6.method disabled connection.autoconnect yes
```

If you have a profile for the Milestone 1 rescue network (`172.16.42.2`) that
could grab the same interface, disable its autoconnect while testing Nura.

### 11. First boot and checks

What we saw: Nura edge reaches `login:` on the screen (text console on
`simpledrm`, display variant A; the display parameters come from the DTB
bootargs). You cannot type there (no touch input, step 13); log in over SSH:

```sh
ping -c3 172.16.43.1
ssh -i <your-key> -o IdentitiesOnly=yes <user>@172.16.43.1
```

Read-only checks we ran inside the phone:

```sh
uname -r                                   # 7.3.0-rc6-zumapro
systemctl is-system-running                # running
systemctl --failed                         # 0 units
findmnt /; losetup -l                      # ext4 root on a loop device over userdata, sector size 4096
df -h /                                    # ours: grown to 221.6 GiB on first boot
grep slot_suffix /proc/bootconfig          # _b
/usr/libexec/google-komodo-ufs-ro --check; echo $?   # 0 = nothing writable except userdata (and its whole LUN)
```

Our result: system `running`, 0 failed units, ext4 root on a loop device
over `userdata` with 4096-byte sectors, resized to 221.6 GiB, 15.1 GiB of RAM,
8 CPUs, slot `_b`, UFS read-only guard `--check` = 0. cpufreq (schedutil)
works.

**Retry counter.** Every boot (and every reboot) of slot B spends one of the
three retries, and nothing marks the slot as successful. Keep count, and
before the last one go to the bootloader and run
`fastboot -s <SERIAL> set_active b`, which reloads them. Getting to the
bootloader from a running Nura is awkward: Power + Volume Down does **not**
reach fastboot from Linux. We got there with a button-forced reboot and then
holding Volume Down; we did not write down the exact combination.

### 12. Back out

- **Back to Android on slot A** (not done by us after flashing `userdata`):
  from the bootloader, `fastboot -s <SERIAL> -w` (**irreversible**: erases
  `userdata`, i.e. Nura, and `metadata`), then `set_active a` and `reboot`.
  Android should start like a freshly reset phone; its data was already lost
  in step 9. Without `-w`, Android finds a `userdata` it cannot decrypt;
  third parties report it reformats it.
- **Back to Nura after a fall-back to A:** if `userdata` still holds Nura,
  `set_active b` from the bootloader. If it was reformatted, flash the
  sparse image again (step 9; that is why you keep the raw image).
- **Back to the Milestone 1 rescue (RAM only):** flash the Milestone 1 images
  with `scripts/flash-slot-b.sh`, `set_active b`, and use the
  `172.16.42.0/24` network. `userdata` is not touched.
- **Slot B to stock:** `scripts/restore-slot-b-stock.sh`
  (see [MILESTONE-1.md](MILESTONE-1.md#7-back-to-android-on-slot-a)).

Slot A, the bootloader, radio and `vbmeta` are never written in this
procedure (not touched on our unit).

### 13. Known problems and limits

Items 1–8 were observed on our unit; item 9 is by design of the UFS guard.

1. **Slot B retry counter:** each boot spends 1 of 3, nothing marks the slot
   successful, and with 0 left the ABL boots slot A. Workaround:
   `fastboot set_active b` beforehand. Unresolved.
2. **First boot, no USB:** on Nura's first boot the PC did not enumerate the
   USB device (errors `-71`). It did not happen again on later boots. Cause
   unknown.
3. **Apparent USB drops** were on the PC side: the host's static IP was lost
   on every re-enumeration (fixed with the NetworkManager profile in step
   10). Two other hypotheses, kernel modules and the UDC rebind done by the
   initramfs hook, were tested live and ruled out.
4. **Buttons:** logind logs "Power key pressed short", but nothing powers off
   or reboots. Power + Volume Down does not reach fastboot from Linux (see
   step 11).
5. **No touch input:** you cannot type at the on-screen login. Access is only
   over SSH, or the initramfs debug shell (telnet, with `pmos.debug-shell`).
6. **No battery or charging support:** there is no `/sys/class/power_supply`.
7. **Serial console with `pmos.debug-shell`:** the debug shell on `ttyGS0`
   comes out garbled (two readers on the port); telnet works.
8. **Modules:** only two load by modalias, `clk-acpm` and `gs101_acpm_tmu`;
   cpufreq (schedutil) works with them.
9. **The whole `sda` LUN stays writable:** it holds `userdata`, and a
   read-only whole disk would make `userdata` read-only too. Its other
   partitions are guarded one by one; a raw write to `/dev/sda` would bypass
   the guard.

### Not verified

- What Android on slot A actually does with a Nura `userdata` (reformat or ask
  for a factory reset).
- Returning to Android with `fastboot -w` after this milestone.
- `KOMODO_INITRAMFS_FORMAT=keep` (zstd initramfs as `vendor_kernel_boot`
  fragment).
- Marking slot B as successful (third-party notes place the counter in
  `devinfo`; not attempted).
- Any hardware beyond what is listed in [STATUS.md](STATUS.md).

---

## Español

### Antes de empezar

- Vale todo lo de [MILESTONE-1.md](MILESTONE-1.md#antes-de-empezar): lee
  [SAFETY.md](SAFETY.md), mismo build stock en los dos slots, slot activo A;
  nunca toques `vbmeta*`, el slot A, `bootloader`, `radio`, `devinfo`, `misc`,
  `efs` ni `persist`. Nunca `flash-all.sh`, nunca `fastboot flashing lock`.
- Haz antes el hito 1, con la **copia privada de las particiones**.
- **Copia tus datos de Android:** se pierden en el paso 9.
- Batería por encima del 50 %, cable directo al PC. **Sin garantía.**

### Resumen de pasos

Los comandos son los de la sección inglesa. `<SERIAL>` es lo que imprime
`fastboot devices`.

1. **Entradas:** pmbootstrap 3.12.1 con configuración, directorio de trabajo
   y copia de pmaports **propios**; canal edge; los paquetes
   `device-google-komodo` y `linux-google-zumapro` de
   [`pmaports/device/testing/`](../pmaports/device/testing/). Kernel: tarball
   de GitHub de `derekross/linux-omamobile` (antes `linux-omarchy-mobile`; la
   URL antigua redirige) en el commit `ffd33b7…` con tres parches de
   pantalla; dentro del tarball la carpeta es `linux-omamobile-<commit>` y es
   idéntica, fichero a fichero, al árbol del hito 1. Clang de Alpine;
   `uname -r` = `7.3.0-rc6-zumapro`. Algunos comentarios de los paquetes
   citan `hito2/PLAN.md`, el plan privado del dueño; este documento es su
   equivalente público.
2. **Copia de pmaports aparte** con un remoto que apunte a la URL oficial, y
   los dos paquetes copiados en `device/testing`.
3. **Configuración aparte** (`pmbootstrap -c … -w … -p …`): canal edge,
   `google`/`komodo`, usuario y hostname a tu gusto, UI **console**, systemd,
   claves SSH sí, con `ssh_key_glob` limitado a **una** clave dedicada. No
   publicamos nuestro `.cfg` (lleva rutas privadas); las líneas relevantes,
   con marcadores neutros, están en la sección inglesa.
4. **Checksum del tarball:** el `APKBUILD` publicado ya lleva el `sha512`
   real y `builddir` con `linux-omamobile`; comparamos además el tarball con
   el árbol del hito 1 con `diff -r`. Si sale alguna diferencia, **para**.
5. **Compilar:** `kconfig check` pasó; el kernel tardó ~21 min con 16 hilos.
6. **Instalar y exportar:** `install` (sin `--split`, `--sdcard` ni
   `--android-recovery-zip`) y `export`.
7. **Imágenes:** `scripts/mkimages-pmos.sh` saca las cinco `_b` y el sparse
   de `userdata`; recomprime el initramfs (15 MB zstd en el nuestro) a lz4
   legacy y comprueba la GPT de 4096. Guarda la imagen raw: es tu copia de la
   raíz. `deviceinfo_flash_method="none"` a propósito: el flasheo es a mano.
8. **Ensayo sin userdata (recomendado):** solo las cinco `_b`, `set_active b`
   y `reboot`. En nuestra unidad el ABL las aceptó, el gadget USB apareció a
   los ~28 s, `ping 172.16.43.1` respondió y el initramfs cayó al debug shell
   por no encontrar raíz. El `userdata` de Android quedó intacto y Android
   arrancó después con normalidad (al agotarse los intentos del slot B el bootloader volvió solo al slot A).
9. **Flashear userdata (irreversible)** desde el bootloader: el sparse de
   834 MB, que fastboot partió en 4 trozos (~23 s); luego `set_active b` y
   `reboot`. Las cinco `_b` ya estaban del ensayo.
10. **Red del PC, antes de arrancar:** subred `172.16.43.0/24` (teléfono .1,
    PC .2). La IP estática puesta a mano se pierde en cada reenumeración;
    varias "caídas de USB" eran eso. Solución: perfil de NetworkManager con
    autoconexión por la MAC fija (inventada) `02:6b:6f:6d:6f:01`.
11. **Primer arranque:** Nura edge llega a `login:` en pantalla (consola
    `simpledrm`). Por SSH: sistema `running`, 0 unidades fallidas, raíz ext4
    en loop sobre `userdata` con sector 4096 redimensionada a 221,6 GiB,
    15,1 GiB de RAM, 8 CPU, slot `_b`, guardia de solo lectura del UFS
    `--check` = 0. **Contador del slot B:** cada arranque gasta un intento;
    antes del último, `fastboot set_active b`. Desde Linux, Encendido +
    Volumen − no lleva a fastboot; llegamos con un reinicio forzado por
    botones manteniendo luego Volumen − (la combinación exacta no quedó
    anotada).
12. **Vuelta atrás:** a Android, `fastboot -w` (**irreversible**, borra Nura;
    no lo hemos hecho), `set_active a`, `reboot`. A Nura tras una caída a A:
    `set_active b`, o reflashear el sparse si `userdata` se reformateó. Al
    rescate del hito 1: `flash-slot-b.sh` con sus imágenes. El slot A, el
    bootloader, la radio y `vbmeta` no se tocan.
13. **Problemas y límites observados:** (1) contador del slot B, sin
    resolver; (2) en el primer arranque el PC no enumeró el USB (errores
    `-71`), no se repitió, causa desconocida; (3) las "caídas de USB" eran del
    PC (IP estática perdida), y las hipótesis de módulos del kernel y del
    religado de la UDC se probaron en vivo y se descartaron; (4) botones:
    logind registra "Power key pressed short" pero no apaga ni reinicia;
    (5) sin táctil: no se puede escribir en el login, acceso solo por SSH o
    por el debug shell del initramfs (telnet con `pmos.debug-shell`); (6) sin
    `/sys/class/power_supply`: batería y carga sin soporte; (7) con
    `pmos.debug-shell`, el debug shell en `ttyGS0` sale entremezclado (dos
    lectores), telnet funciona; (8) solo cargan dos módulos por modalias,
    `clk-acpm` y `gs101_acpm_tmu`, y cpufreq (schedutil) funciona con ellos;
    (9) por diseño de la guardia, el LUN entero `sda` queda escribible
    (contiene `userdata`).

### Sin verificar

Qué hace realmente Android en el slot A con un `userdata` de Nura; volver a
Android con `fastboot -w` después de este hito; el initramfs en zstd
(`KOMODO_INITRAMFS_FORMAT=keep`); marcar el slot B como correcto (según notas de
terceros, el contador está en `devinfo`; no se ha intentado); el resto del hardware
([STATUS.md](STATUS.md)).
