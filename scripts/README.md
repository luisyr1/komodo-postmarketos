# scripts/

Build and flashing helpers for Milestone 1 (RAM-only Linux on slot B). The
procedure that uses them is in [../docs/MILESTONE-1.md](../docs/MILESTONE-1.md);
read [../docs/SAFETY.md](../docs/SAFETY.md) first. **No warranty.**

Herramientas de build y flasheo del hito 1 (Linux solo en RAM en el slot B).
El procedimiento está en [../docs/MILESTONE-1.md](../docs/MILESTONE-1.md); lee
antes [../docs/SAFETY.md](../docs/SAFETY.md). **Sin garantía.**

Rules / Reglas:

- Scripts must never write backups, dumps or logs inside the repository tree,
  and must never print or store unique device identifiers. / Los scripts no
  deben escribir copias, volcados ni logs dentro del repositorio, ni imprimir o
  guardar identificadores únicos.
- Every shell script requires `KOMODO_WORK`, a **private** work directory
  outside this repository (they refuse to run if it is inside it). There are no
  default paths outside it. `treedigest.py` does not need it. / Todos los
  scripts de shell exigen `KOMODO_WORK`, un directorio de trabajo **privado**
  fuera del repositorio (se niegan si está dentro); no hay rutas por defecto
  fuera de él. `treedigest.py` no lo necesita.
- Every path a script **writes or deletes** must resolve (symlinks included)
  to a subdirectory of `KOMODO_WORK`; otherwise the script aborts before
  touching anything. No script uses `TMPDIR`. / Toda ruta que un script
  **escribe o borra** tiene que resolverse (con enlaces incluidos) dentro de
  `KOMODO_WORK`; si no, el script aborta sin tocar nada. Ningún script usa
  `TMPDIR`.
- **None of them downloads anything.** You fetch the inputs listed below
  yourself and check their hashes. / **Ninguno descarga nada.** Las entradas de
  abajo las descargas tú y compruebas sus hashes.
- Comments inside the scripts are mostly in Spanish. / Los comentarios
  internos están sobre todo en español.

## Work directory layout / Estructura de `KOMODO_WORK`

Defaults, each overridable with the variable in brackets. All variables carry
the `KOMODO_` prefix so they cannot collide with other build environments
(AOSP's `envsetup.sh`, for instance, exports `OUT`). / Valores por defecto;
cada uno se puede cambiar con la variable entre corchetes. Todas llevan el
prefijo `KOMODO_` para no chocar con otros entornos (el `envsetup.sh` de AOSP,
por ejemplo, exporta `OUT`).

```text
$KOMODO_WORK/
  src/linux-ffd33b7/            kernel tree [KOMODO_KERNEL_SRC]
  src/omamobile/                Omamobile checkout [KOMODO_OMAMOBILE_DIR]
                                (kernel/configs/omamobile.config, initramfs/init)
  downloads/clang-r596125/tree/ extracted Android clang [KOMODO_CLANG_DIR]
  downloads/alpine/alpine-minirootfs-3.24.2-aarch64.tar.gz   [KOMODO_MINIROOTFS]
  downloads/alpine/apks/*.apk + SHA256SUMS                    [KOMODO_APK_DIR]
  downloads/avb/testkey_rsa4096.pem                            [KOMODO_AVB_KEY]
  keys/komodo_initramfs_ed25519.pub   dedicated SSH public key [KOMODO_PUBKEY]
  build/kernel-out/             kernel build output [KOMODO_KOUT]          (*)
  build/initramfs/              initramfs work dir [KOMODO_INITRAMFS_WORK] (*)
  build/initramfs/initramfs.cpio.lz4  initramfs used by mkimages [KOMODO_INITRAMFS]
  build/images/                 the five images [KOMODO_IMG_DIR]           (*)
  stock/slot-b-stock/           stock images [KOMODO_STOCK_IMG_DIR]        (*)
  stock/image-komodo-cp4a.261105.040.a1.zip               [KOMODO_STOCK_ZIP]
```

`(*)` = written, emptied or read for flashing: must be **inside**
`KOMODO_WORK` (not `KOMODO_WORK` itself), checked with `realpath`. / Se
escribe, se vacía o se lee para flashear: tiene que estar **dentro** de
`KOMODO_WORK` (no ser el propio `KOMODO_WORK`), comprobado con `realpath`.

| Variable | Script(s) | Default / Por defecto |
|---|---|---|
| `KOMODO_WORK` | all shell scripts / todos los de shell | **required / obligatoria** |
| `KOMODO_KERNEL_SRC` | `build-kernel.sh` | `src/linux-ffd33b7` |
| `KOMODO_KOUT` (*) | `build-kernel.sh` (output), `mkimages.sh`, `verify-images.sh` | `build/kernel-out` |
| `KOMODO_CLANG_DIR` | `build-kernel.sh` | `downloads/clang-r596125/tree` |
| `KOMODO_OMAMOBILE_CONFIG` | `build-kernel.sh` | `src/omamobile/kernel/configs/omamobile.config` |
| `KOMODO_SKIP_TOOLCHAIN_CHECK` | `build-kernel.sh` | unset; `1` skips the clang tree digest on purpose / sin definir; `1` salta a propósito el digest de clang |
| `KOMODO_OMAMOBILE_DIR` | `mkinitramfs.sh` | `src/omamobile` |
| `KOMODO_INIT_SRC` | `mkinitramfs.sh` | `$KOMODO_OMAMOBILE_DIR/initramfs/init` (SHA-256 pinned, not overridable / fijado, no se puede cambiar) |
| `KOMODO_MINIROOTFS` | `mkinitramfs.sh` | `downloads/alpine/alpine-minirootfs-3.24.2-aarch64.tar.gz` |
| `KOMODO_APK_DIR` | `mkinitramfs.sh` | `downloads/alpine/apks` |
| `KOMODO_PUBKEY` | `mkinitramfs.sh` | `keys/komodo_initramfs_ed25519.pub` (only type and key are copied, not the comment / solo se copian tipo y clave, sin comentario) |
| `KOMODO_INITRAMFS_WORK` (*) | `mkinitramfs.sh` (output; `stage/` inside is deleted and rebuilt / `stage/` se borra y se rehace) | `build/initramfs` |
| `KOMODO_INITRAMFS` | `mkimages.sh` | `build/initramfs/initramfs.cpio.lz4` |
| `KOMODO_AVB_KEY` | `mkimages.sh`, `verify-images.sh` | `downloads/avb/testkey_rsa4096.pem` |
| `KOMODO_OVERLAY_SRC` | `mkimages.sh` | `device/komodo-board-overlay.dts` (in the repository / del repositorio) |
| `KOMODO_VENDOR_CMDLINE` | `mkimages.sh` | bring-up cmdline in the script / la del script |
| `KOMODO_IMG_DIR` (*) | `mkimages.sh` (output, emptied of `*.img` etc. / se vacía de `*.img` etc.), `verify-images.sh` (or its argument / o su argumento), `flash-slot-b.sh` | `build/images` |
| `KOMODO_STOCK_IMG_DIR` (*) | `restore-slot-b-stock.sh` (extracts into it / extrae ahí) | `stock/slot-b-stock` |
| `KOMODO_STOCK_ZIP` | `restore-slot-b-stock.sh` | `stock/image-komodo-cp4a.261105.040.a1.zip` |

`verify-images.sh` creates its temporary directory inside `KOMODO_WORK` and
removes it on exit. / `verify-images.sh` crea su directorio temporal dentro de
`KOMODO_WORK` y lo borra al salir.

> **Build-specific values / Valores específicos del build.** The constants
> pinned in `flash-slot-b.sh` (`WANT_BL`, partition sizes, `WANT_ROLLBACK`),
> `restore-slot-b-stock.sh`, `mkimages.sh` (`OS_VERSION`, `OS_PATCH_LEVEL`,
> `AVB_ROLLBACK_INDEX`, `AVB_SECURITY_PATCH`, `DTBO_ID`/`DTBO_REV`) and
> `verify-images.sh` are **specific to build `CP4A.261105.040.A1`** (= values
> from that build's stock vbmeta/footers). On any other build take them from
> the stock images actually installed; **never use a rollback index higher
> than stock.** / Son **específicos del build `CP4A.261105.040.A1`** (= valores
> del vbmeta y los pies stock de ese build). Con cualquier otro build, tómalos
> de las imágenes stock realmente instaladas; **nunca uses un rollback index
> mayor que el de stock.**

## Scripts, in order of use / En orden de uso

| # | Script | What it does / Qué hace | Touches the phone? |
|---|---|---|---|
| 0 | `treedigest.py` | Tree digest of a directory (Omamobile `toolchain.lock` "tree" algorithm). Used to check the extracted clang: `python3 -I scripts/treedigest.py "$KOMODO_WORK/downloads/clang-r596125/tree"`. / Digest del árbol de clang extraído. | no |
| 1 | `build-kernel.sh` | Before building: checks the clang tree digest against the pin (with `treedigest.py`; `KOMODO_SKIP_TOOLCHAIN_CHECK=1` skips it explicitly) and, if the kernel tree is a git checkout, that it is at commit `ffd33b7…` (if it is not a checkout, e.g. a `git archive` export, it only warns). Then `defconfig` + `omamobile.config`, `LLVM=1`, builds `Image`, DTBs and modules with a generic build identity. / Comprueba clang y el commit del kernel y compila. | no |
| 2 | `mkinitramfs.sh` | `ram-rescue` initramfs: Alpine minirootfs + dropbear + Omamobile's `/init` (SHA-256 pinned), no UFS write list; `authorized_keys` gets only the type and key of your public key (no comment). Output `initramfs.cpio.lz4`. / Initramfs de rescate. | no |
| 3 | `mkimages.sh` | The five slot-B images with AVB hash footers (AOSP test key). Checks pinned `mkbootimg`/`mkdtboimg`/`avbtool` hashes and the DTB `/soc_compatible` node. Uses [`../device/komodo-board-overlay.dts`](../device/komodo-board-overlay.dts). / Las cinco imágenes. | no |
| 4 | `verify-images.sh` | Offline check of everything `mkimages.sh` produced (sizes, AVB footer, key, rollback index, props, headers, initramfs contents). / Verificación offline. | no |
| 5 | `flash-slot-b.sh` | `--dry-run <SERIAL>` first: preflight (one device, `komodo`, unlocked, bootloader version, active slot A and successful, partition sizes, image hashes, and an AVB footer on every image with its partition name, `SHA256_RSA4096` and the expected rollback index, read with `avbtool info_image`; so `avbtool` must be on the `PATH`, passing `verify-images.sh` alone is not accepted). Without `--dry-run`, asks you to type `FLASH-B` and flashes **only** the five `_b` partitions, recomputing each image's SHA-256 right before its `flash` and aborting if it changed. Never changes the active slot, never reboots. / Flashea solo las cinco `_b`. | **yes** |
| 6 | `restore-slot-b-stock.sh` | Same preflight; flashes the five `_b` boot partitions back to the stock images of `CP4A.261105.040.A1` (SHA-256 of the public factory image pinned, recomputed right before each `flash`). Asks for `RESTAURAR-B`. / Devuelve el slot B a stock. | **yes** |

Both flashing scripts tell a variable the bootloader does not have ("Variable
not found", "unknown variable"…) apart from any other `fastboot` error, which
aborts. / Los dos scripts de flasheo distinguen una variable que el bootloader
no tiene de cualquier otro error de `fastboot`, que aborta.

`set_active`, `reboot` and the return to slot A are done **by hand**, as
described in [MILESTONE-1.md](../docs/MILESTONE-1.md). / El cambio de slot,
el reinicio y la vuelta al slot A se hacen **a mano**.

`<SERIAL>` is what `fastboot devices` prints. Pass it on the command line; do
not write it to files you might share. / `<SERIAL>` es lo que imprime
`fastboot devices`; no lo guardes en ficheros que puedas compartir.

## Host requirements / Requisitos del host

`bash`, `python3`, `make`, `tar`, `cpio`, `lz4`, `sha256sum`, `unzip`,
**`bc`** (needed by the kernel build, `kernel/time/timeconst.bc`; install it
from your distribution), `mkbootimg`, `unpack_bootimg`, `mkdtboimg` and
`avbtool` (e.g. Arch `android-tools` 37, whose copies matched the Omamobile
pins on our host; `mkimages.sh` refuses any other version), and `fastboot` for
steps 5–6.

## Downloads you need / Descargas necesarias

Download them yourself, into `$KOMODO_WORK/downloads/`, and check every hash
before use. / Descárgalas tú y comprueba cada hash antes de usarlas.

| Input | Source | Pinned hash |
|---|---|---|
| Kernel tree | <https://github.com/derekross/linux-omarchy-mobile> PR #276, fork `oscarluke`, branch `omamobile-komodo-m1`, commit `ffd33b7ddc716eb3568fff9f8d337a4032d109eb` (export with `git archive`) | git commit id |
| Omamobile | <https://github.com/derekross/omamobile>, commit `15a7d20ce3fab68e8e4905590c6c2c2b5db15c8a` (`initramfs/init`, `kernel/configs/omamobile.config`, `tools/toolchain.lock`) | `initramfs/init` SHA-256 pinned in `mkinitramfs.sh` |
| Android clang r596125 | <https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/29182889399818f97baa65ea238c80e8117981eb/clang-r596125.tar.gz> (gitiles builds the tarball on the fly, so the tarball hash is not stable: check the **extracted tree**) | tree digest `111d4532e29ceb47cd6392ded7319c24d8ae5dd510b9a0770fc7bcb5d27a7881` (`treedigest.py`, same as Omamobile `toolchain.lock`) |
| Alpine minirootfs 3.24.2 aarch64 | <https://dl-cdn.alpinelinux.org/alpine/v3.24/releases/aarch64/alpine-minirootfs-3.24.2-aarch64.tar.gz> | SHA-256 `9bf70a7f18ea44094cbb5f70c58f9af129c8214745743db0e68e5502cc2ce773` |
| `dropbear-2026.91-r0.apk` | <https://dl-cdn.alpinelinux.org/alpine/v3.24/main/aarch64/dropbear-2026.91-r0.apk> | SHA-256 `83547e6936b7c90b1625514bd3497d5c7152fcdb66bcae3b68a8e51fdfe31090` |
| `utmps-libs-0.1.3.3-r0.apk` | <https://dl-cdn.alpinelinux.org/alpine/v3.24/main/aarch64/utmps-libs-0.1.3.3-r0.apk> | SHA-256 `d6487b6f260728969191314f6706d4cc62527370e757ec3ac6f7fee8ed38cf88` |
| `skalibs-libs-2.15.0.0-r0.apk` | <https://dl-cdn.alpinelinux.org/alpine/v3.24/main/aarch64/skalibs-libs-2.15.0.0-r0.apk> | SHA-256 `7ea58fb512067402b519079fcce8a48381eb2b9c690341c4a017aa15f719c198` |
| `avbtool` | <https://android.googlesource.com/platform/external/avb/+/ba2dec4b035b0a3b61c5f8f8a74d86bcd450b1ee/avbtool.py?format=TEXT> (base64) | SHA-256 (decoded) `1aa6f2b462aa67aa3fdf488bee83ab517de8ad9d8228c7b45c35267ab2cf6781` |
| AOSP test key `testkey_rsa4096.pem` | <https://android.googlesource.com/platform/external/avb/+/ba2dec4b035b0a3b61c5f8f8a74d86bcd450b1ee/test/data/testkey_rsa4096.pem?format=TEXT> (base64) | SHA-256 (decoded) `6a224754880a57ab9cbd308267cd157d94cf05a1c8cb851aec4090e045d24121` |
| Factory image `CP4A.261105.040.A1` (only for `restore-slot-b-stock.sh`) | Google's official factory images page for `komodo` | check against Google's table; the five extracted images are pinned in the script |

The three `.apk` files were additionally checked against the **signed**
Alpine v3.24 `APKINDEX.tar.gz` (signature key `…616ae350.rsa.pub`, verified
with the key shipped in the minirootfs): each package's `C:` (Q1, SHA-1) field
matched. Do the same; `mkinitramfs.sh` only checks your `SHA256SUMS` file. /
Los tres `.apk` se comprobaron además contra el `APKINDEX` **firmado** de
Alpine v3.24 (campo `C:`); hazlo tú también, porque el script solo comprueba tu
`SHA256SUMS`.

The test key is **public** (anyone can sign with it). It is only acceptable
because the bootloader is unlocked; it gives no security. / La clave de prueba
es **pública**; solo sirve porque el bootloader está desbloqueado y no aporta
seguridad.

## What is not here / Qué no está aquí

No images, no keys, no checksums of built images, no backups. Generate your
own SSH key pair for the initramfs and keep the private half outside the
repository. / Ni imágenes, ni claves, ni sumas de imágenes generadas, ni copias
de seguridad. Genera tu propio par de claves SSH y guarda la privada fuera del
repositorio.
