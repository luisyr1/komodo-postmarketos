# Marking slot B successful / Marcar el slot B como correcto

Done on our unit on 2026-11-26 (see [JOURNAL.md](JOURNAL.md)). Read
[SAFETY.md](SAFETY.md#devinfo-the-one-exception--la-única-excepción) first:
this is the **only** write to `devinfo` this project allows, and it is your
decision. Nothing here runs by default.

Hecho en nuestra unidad el 2026-11-26. Lee antes
[SAFETY.md](SAFETY.md#devinfo-the-one-exception--la-única-excepción): es la
**única** escritura en `devinfo` que permite este proyecto y la decides tú.
Nada de esto se ejecuta por defecto. (Resumen en español al final.)

## Why / Por qué

The Pixel bootloader (ABL) takes one retry from a slot on every boot until
the slot is marked `successful`. Android's boot-control HAL marks it after
every good boot; Linux does not, so every boot of slot B spends one of its
3 retries, and at 0 the ABL boots slot A, whose Android reportedly
reformats `userdata` (where the Linux root lives). The mark is one bit in
the flags byte of slot B in `devinfo`.

| Offset | Bytes | Meaning |
|---|---|---|
| `0x04` | `u16` major, `u16` minor | layout version; ours is **3.19** |
| `0x30–0x33` | retry, flags, 0, 0 | slot A |
| `0x34–0x37` | retry, flags, 0, 0 | slot B |

Flags, least significant bit first: bit 0 `unbootable`, bit 1 `successful`,
bit 2 `active`, bit 3 `fastboot_ok`; bit 4 is set on both slots, meaning
unknown, preserved. On our unit slot B read `02 14 00 00` before (2
retries; active; not successful) and the write turned `0x35` from `14`
into `16`. The rest of the partition holds factory records with unique
identifiers: `komodo-bootctl` never prints their values, and you should
never publish a copy.

## What you need / Qué hace falta

- Nura booted from slot B, a USB cable to the PC, enough battery, `fastboot`
  on the PC.
- `/usr/bin/komodo-bootctl`. Device package `pkgrel=4` builds and installs
  it (with abuild's flags plus `-Wall -Wextra`; built, installed and checked
  on our unit on 2026-11-26). With an older device package, build it on the
  phone from
  [`komodo-bootctl.c`](../pmaports/device/testing/device-google-komodo/komodo-bootctl.c)
  (needs `gcc`, `musl-dev`, `linux-headers`):
  `gcc -O2 -Wall -Wextra -Werror -o komodo-bootctl komodo-bootctl.c` (what
  we used on our unit before `pkgrel=4`) and
  `sudo install -m 0755 komodo-bootctl /usr/bin/`. Remove that copy before
  installing `pkgrel=4`, so the packaged one owns the path.
- `/usr/libexec/komodo-boot-success` and the read-only guard
  `/usr/libexec/google-komodo-ufs-ro`, both from the device package.

## 1. Before / Antes (fastboot)

```sh
fastboot getvar current-slot          # b
fastboot getvar slot-successful:b     # no
fastboot getvar slot-retry-count:b    # note it; at least 2
fastboot getvar slot-unbootable:b     # no
```

If the count is low, reload it first with `fastboot set_active b` (3
retries), then `fastboot reboot`.

## 2. Find and decode `devinfo` (read-only) / Localizar y decodificar

```sh
grep -l '^PARTNAME=devinfo$' /sys/class/block/sd*/uevent
# exactly one line, e.g. /sys/class/block/sdd1/uevent on our unit
P=sdd1; D=sdd        # YOURS: the partition found above and its disk (LUN)
readlink -f /sys/class/block/$P      # .../$D/$P: confirms the disk
sudo komodo-bootctl dump /dev/$P
```

`sdX` names are **not** guaranteed to be the same on another unit, or even
on another boot: always take `P` and `D` from this step (or from the
wrapper's log line `devinfo is /dev/<partition> on /dev/<disk>`), in the
same shell session as the commands below. / Los nombres `sdX` **no** están
garantizados entre unidades ni entre arranques: saca siempre `P` y `D` de
este paso (o de la línea del envoltorio `devinfo is /dev/<partición> on
/dev/<disco>`), en la misma sesión que las órdenes siguientes.

Expected: version 3.19, slot b active, not successful, the retry count you
noted, and the consistency check passing. Any other version: stop, the tool
refuses to write it anyway.

## 3. Dry run / Ensayo

```sh
sudo /usr/libexec/komodo-boot-success
```

It must print `planned change: offset 0x35: 14 -> 16` (your value may
differ only if your flags differ; it must be offset `0x35`) and `dry run
only`. It also leaves a root-only copy of the partition in
`/var/lib/komodo-boot-success/` (`devinfo-first.img` is never
overwritten).

## 4. Rehearse on a file copy / Ensayo sobre una copia

```sh
sudo sh -c "umask 077; mkdir -p /root/devinfo-test
  cat /dev/$P > /root/devinfo-test/before.img
  cp /root/devinfo-test/before.img /root/devinfo-test/test.img"
sudo komodo-bootctl mark-successful /root/devinfo-test/test.img b --write --i-understand-devinfo
sudo cmp -l /root/devinfo-test/before.img /root/devinfo-test/test.img
```

`cmp -l` must print exactly one line: `54 24 26` (byte 54 counted from 1,
i.e. offset `0x35`; old and new values in octal, `0x14` and `0x16`; the
spacing may differ). The copies contain your phone's serial numbers and
IMEI: keep them private (`devinfo` belongs in your private backup, see
[SAFETY.md](SAFETY.md)) and delete `/root/devinfo-test/` when done.

## 5. Write / Escritura

With the cable connected and enough battery, once, by hand:

```sh
sudo /usr/libexec/komodo-boot-success --write
cat /sys/class/block/$P/ro /sys/class/block/$D/ro          # 1 and 1
sudo /usr/libexec/google-komodo-ufs-ro --check; echo $?   # 0
```

Expected: `written and verified (8192 bytes compared, 1 byte changed)` and
`slot b marked successful`. The wrapper finds the partition by itself, opens
the guard for that partition and its disk only and relocks them on exit
(and again after 60 s through a systemd timer). If it prints `VERIFY
FAILED` (exit code 3 of `komodo-bootctl`; the wrapper itself exits with 1):
do **not** reboot, go to "Undo and recovery" below.

## 6. Verify in fastboot / Verificar en fastboot

Two or three rounds, **without** `set_active`:

```sh
sudo reboot bootloader                # on the phone
fastboot getvar slot-successful:b     # yes
fastboot getvar slot-retry-count:b    # the same value as before, every round
fastboot getvar current-slot          # b
fastboot getvar slot-unbootable:b     # no
fastboot reboot
```

On our unit: `yes`, `2`, `b`, `no` in all three rounds. The counter no
longer drops.

## 7. Optional: the timer / Opcional: el temporizador

```sh
sudo systemctl enable komodo-boot-success.timer
```

Enabled on our unit. It runs the write 2 minutes after a boot reaches
`multi-user.target`, and does nothing (without opening the guard) while
slot B is already marked. It matters after anything that clears the mark:
Omamobile reports that `fastboot set_active b` and flashing a `_b`
partition do so on the Pixel 9a (`tegu`); not re-measured on `komodo`. A
kernel that panics or hangs before those 2 minutes is not marked and keeps
spending retries.

## Consequence / Consecuencia

With slot B marked, the ABL **no longer falls back to slot A by itself**
(deduced: no failed boot has been tried with B marked). A broken image on
slot B is repaired by hand: Power + Volume Down to reach fastboot, then
reflash the `_b` images or `fastboot --set-active=a`.

## Undo and recovery / Deshacer y recuperar

- **Undo the mark:** `fastboot set_active b` should rewrite slot B to 3
  retries, not successful (reported by Omamobile on `tegu`; not verified
  on `komodo`). That is not exactly the state before the write: ours had 2
  retries left then.
- **Stop the marking:** `sudo systemctl disable komodo-boot-success.timer`
  and `sudo touch /etc/komodo/no-boot-success`, or `komodo.no_boot_success`
  on the kernel command line.
- **If `VERIFY FAILED` was printed (exit code 3 of `komodo-bootctl`; the
  wrapper exits with 1), without rebooting**, write back the copy the
  wrapper took just before. **Check that `P` is your `devinfo` before
  writing** (the two checks below stop otherwise). / **Comprueba que `P` es
  tu `devinfo` antes de escribir** (las dos comprobaciones de abajo paran si
  no lo es).

  ```sh
  P=sdd1; D=sdd   # YOURS, from step 2 or the wrapper's log line
  grep -qx PARTNAME=devinfo /sys/class/block/$P/uevent || exit 1
  [ "$(cat /sys/class/block/$P/size)" = 16 ] || exit 1
  sudo blockdev --setrw /dev/$D; sudo blockdev --setrw /dev/$P
  sudo dd if=/var/lib/komodo-boot-success/devinfo-latest.img of=/dev/$P bs=4096 conv=fsync
  sudo blockdev --flushbufs /dev/$P
  sudo cmp /dev/$P /var/lib/komodo-boot-success/devinfo-latest.img
  sudo blockdev --setro /dev/$P; sudo blockdev --setro /dev/$D
  ```

  (`exit 1` closes an interactive shell: that is intended; paste the block
  into a fresh `sh` if you prefer.) `fastboot flash devinfo` is most likely
  not allowed (not verified), so the copy can only be restored from Linux.

## Not verified / Sin verificar

- That `fastboot set_active b` and flashing a `_b` partition clear the mark
  on `komodo` (reported on `tegu`).
- That the ABL would boot slot B again after a failed boot with B marked
  (no failure has been provoked).
- Behaviour after a fully drained battery, and with layouts other than
  3.19 (the tool refuses them).
- The meaning of flags bit 4.
- Done once, on one unit.

## Known issues / Problemas conocidos

Pending for the next revision of the device package (none of them writes
anything): / Pendientes para la próxima revisión del paquete (ninguno
escribe nada):

- The comment above `write_slot_flag()` in `komodo-bootctl.c` says the
  before-image is printed as a path when the verification fails; the code
  prints no path. / El comentario de `write_slot_flag()` dice que, si falla
  la verificación, se imprime la ruta de la copia previa; el código no
  imprime ninguna ruta.
- `komodo-boot-success` treats a missing `komodo-bootctl` (or an error from
  `check`) as "not marked": it takes its copy and then fails at the dry
  run, without writing. / `komodo-boot-success` trata la falta de
  `komodo-bootctl` (o un error de `check`) como «no marcado»: hace la copia
  y falla en el ensayo, sin escribir.
- `komodo-boot-success.timer` does not check `komodo.no_boot_success` on
  the kernel command line; the `.service` (and the script) do. /
  `komodo-boot-success.timer` no comprueba `komodo.no_boot_success`; el
  `.service` (y el script) sí.

## Resumen

El ABL resta un intento al slot en cada arranque hasta que el slot está
marcado `successful`; Android lo marca con su HAL y Linux no, así que cada
arranque de B gastaba uno de sus 3 intentos y a 0 el ABL arrancaba el slot
A. La marca es el bit 1 del byte de flags del slot B en `devinfo`
(`0x35`). Pasos: (1) en fastboot, anota `slot-retry-count:b` (al menos 2;
si no, `fastboot set_active b`); (2) localiza `devinfo` y guarda en `P` tu
partición y en `D` su disco (`sdd1` y `sdd` en nuestra unidad; los nombres
`sdX` no están garantizados) y haz `komodo-bootctl dump /dev/$P` en solo
lectura: versión 3.19, B activo y sin marcar; (3) ensayo con
`komodo-boot-success` sin argumentos: tiene que planear `0x35: 14 -> 16`;
(4) prueba sobre una copia en fichero: `cmp -l` debe dar una sola línea,
`54 24 26`; las copias llevan tus números de serie e IMEI, guárdalas en
privado y borra las de prueba; (5) con el cable y batería suficiente, una
vez y a mano, `komodo-boot-success --write`: «written and verified (8192
bytes compared, 1 byte changed)», `ro` = 1 en `$P` y `$D` y `--check` = 0
(si sale el mensaje `VERIFY FAILED`, código 3 de `komodo-bootctl`, con el
que el envoltorio sale con 1, no reinicies y restaura la copia como arriba,
comprobando antes que `P` es tu `devinfo`); (6) dos o tres rondas `reboot
bootloader` → `getvar` → `fastboot reboot`, **sin** `set_active`:
`slot-successful:b` = yes y el mismo `slot-retry-count:b` cada vez (en
nuestra unidad, 2 las tres veces); (7) opcional, `systemctl enable
komodo-boot-success.timer` (activado en nuestra unidad): marca a los 2 min
de un arranque bueno y vuelve a marcar tras algo que borre la marca (según
Omamobile en `tegu`, `set_active b` y flashear `*_b`; sin volver a medir en
`komodo`); un kernel que cae o se cuelga antes de esos 2 min no se marca y
sigue gastando intentos. Parar el marcado: `systemctl disable
komodo-boot-success.timer` y `touch /etc/komodo/no-boot-success`, o
`komodo.no_boot_success` en la línea de arranque del kernel. Consecuencia:
el ABL **ya no vuelve solo al slot A** (deducción: no se ha provocado un
fallo con B marcado); una imagen rota en B se repara a mano desde fastboot
(Encendido + Volumen −). Deshacer: `fastboot set_active b` debería dejar el
slot B con 3 intentos y sin marcar (según Omamobile en `tegu`; sin verificar
en `komodo`; no es exactamente el estado previo, que tenía 2 intentos). Sin
verificar: que `set_active b` y el flasheo borren la marca en `komodo`, que
el ABL vuelva a arrancar B tras un fallo con B marcado, el comportamiento
con la batería agotada, el significado del bit 4. Hecho una vez, en una
unidad.
