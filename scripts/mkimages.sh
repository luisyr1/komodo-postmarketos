#!/bin/bash
# SPDX-License-Identifier: MIT
# Image layout adapted from Omamobile (bin/omamobile, boot image packing), MIT
# License, Copyright (c) 2026 Derek Ross and Omamobile contributors.
# Also builds on the komodo bring-up work in Omamobile: PRs #914 and #567 of
# derekross/omamobile (the bring-up vendor_cmdline below comes from #914).
# Parte tambien del bring-up de komodo en Omamobile: PR #914 y #567 de
# derekross/omamobile (la vendor_cmdline de bring-up sale de la #914).
#
# Builds the five slot-B images (Milestone 1). Never calls fastboot or adb and
# downloads nothing. See scripts/README.md and docs/MILESTONE-1.md.
#
# mkimages.sh - monta las cinco imagenes del slot B del Pixel 9 Pro XL (komodo)
# para el primer arranque de Linux mainline. Solo construye ficheros: este
# script NO contiene ni llama a fastboot ni a adb.
#
#   KOMODO_WORK=... scripts/mkimages.sh            todas las que se puedan
#   KOMODO_WORK=... KOMODO_KOUT=... KOMODO_INITRAMFS=... KOMODO_IMG_DIR=... scripts/mkimages.sh
#
# Entradas (por defecto, bajo $KOMODO_WORK):
#   KOMODO_KOUT        build/kernel-out  (arch/arm64/boot/Image, el DTB, scripts/dtc/dtc)
#   KOMODO_INITRAMFS   build/initramfs/initramfs.cpio.lz4 (si falta: se omite vendor_kernel_boot)
#   KOMODO_AVB_KEY     downloads/avb/testkey_rsa4096.pem  (clave de prueba AOSP)
#   KOMODO_OVERLAY_SRC device/komodo-board-overlay.dts del repositorio
#   KOMODO_VENDOR_CMDLINE  cmdline de bring-up (ver abajo)
# Salida (tiene que estar dentro de KOMODO_WORK; se vacia de *.img etc.):
#   KOMODO_IMG_DIR     build/images
# Herramientas del host (p. ej. android-tools 37): mkbootimg, mkdtboimg y
# avbtool deben tener el mismo SHA-256 que el pin de omamobile/tools/toolchain.lock;
# el script lo comprueba y se niega si no coinciden.
#
# Diseno (contrastado con stock CP4A.261105.040.A1 y bin/omamobile ~1040-1183):
#   boot                v4, kernel Image.lz4, cmdline ''
#   init_boot           v4, ramdisk vacio, os_version 17.0.0, patch 2026-11
#   vendor_boot         v4, pagesize 0x800, vendor_cmdline de bring-up,
#                       un fragmento vacio (type 1 = PLATFORM, nombre '')
#   vendor_kernel_boot  v4, pagesize 0x800, vendor_cmdline '', dtb.img,
#                       fragmento initramfs.cpio.lz4 (type 1, nombre '')
#   dtbo                mkdtboimg, page 4096, id 0x60806 rev 0x10000, overlay vacio
#   Pie AVB en las cinco: SHA256_RSA4096 con la clave de prueba, rollback
#   1793836800 (2026-11-05 00:00 UTC), props os_version 17 y security_patch
#   2026-11-05, sal = SHA-256 de la imagen sin pie (salida reproducible).
set -euo pipefail

: "${KOMODO_WORK:?set KOMODO_WORK to your private work directory}"
REPO=$(cd "$(dirname "$0")/.." && pwd -P)
[[ -d $KOMODO_WORK ]] || { echo "error: KOMODO_WORK no es un directorio" >&2; exit 1; }
case "$(cd "$KOMODO_WORK" && pwd -P)/" in "$REPO"/*) echo "error: KOMODO_WORK no puede estar dentro del repositorio" >&2; exit 1 ;; esac
die() { printf 'error: %s\n' "$*" >&2; exit 1; }
say() { printf '==> %s\n' "$*"; }
# Toda ruta que se escribe o se borra tiene que quedar DENTRO de KOMODO_WORK
inside_work() { # ruta nombre-de-variable
  [[ -n $1 ]] || die "$2 esta vacia"
  case "$(realpath -m -- "$1")/" in
    "$(realpath -- "$KOMODO_WORK")"/?*) ;;
    *) die "$2=$1 queda fuera de KOMODO_WORK" ;;
  esac
}
KOUT=${KOMODO_KOUT:-$KOMODO_WORK/build/kernel-out}
INITRAMFS=${KOMODO_INITRAMFS:-$KOMODO_WORK/build/initramfs/initramfs.cpio.lz4}
AVB_KEY=${KOMODO_AVB_KEY:-$KOMODO_WORK/downloads/avb/testkey_rsa4096.pem}
OUT=${KOMODO_IMG_DIR:-$KOMODO_WORK/build/images}
inside_work "$OUT" KOMODO_IMG_DIR
OVERLAY_SRC=${KOMODO_OVERLAY_SRC:-$REPO/device/komodo-board-overlay.dts}
DTB_REL=exynos/google/zumapro-komodo.dtb

# Bring-up: lo que usa device/komodo/device.conf de la PR #914 de Omamobile mas panic=10,
# del que depende la auto-recuperacion USB del init (echo c > sysrq-trigger
# -> reinicio -> ABL agota reintentos del slot B -> vuelve a A).
VENDOR_CMDLINE=${KOMODO_VENDOR_CMDLINE:-"console=tty0 clk_ignore_unused pd_ignore_unused printk.devkmsg=on panic=10 bootconfig"}
# Specific to build CP4A.261105.040.A1 (= values from that build's stock
# vbmeta/footers). On any other build take them from the stock images actually
# installed; never use a rollback index higher than stock.
# Especifico del build CP4A.261105.040.A1 (= valores del vbmeta y los pies
# stock de ese build). Con cualquier otro build, tomalos de las imagenes stock
# realmente instaladas; nunca uses un rollback index mayor que el de stock.
OS_VERSION=17.0.0
OS_PATCH_LEVEL=2026-11
AVB_ROLLBACK_INDEX=1793836800
AVB_SECURITY_PATCH=2026-11-05
DTBO_ID=0x60806
DTBO_REV=0x10000
# Tamanos de las particiones _b (del modelo; ver docs/DEVICE.md). Specific to
# build CP4A.261105.040.A1; on any other build take them from the stock images
# actually installed. / Especificos de ese build; con otro, de las imagenes
# stock instaladas.
declare -A PART_SIZE=(
  [boot]=0x4000000
  [init_boot]=0x800000
  [vendor_boot]=0x4000000
  [vendor_kernel_boot]=0x4000000
  [dtbo]=0x1000000
)

[[ -f $OVERLAY_SRC ]] || die "no hay overlay en $OVERLAY_SRC"

# Herramientas fijadas: mismo hash que toolchain.lock de Omamobile
declare -A PIN=(
  [mkbootimg]=37d84b3d162e0bc62e36c1f4e1c63c85ea0caa9f29be023eb2f8efe006ad948c
  [mkdtboimg]=81656c0e344ad2c9e7bdc6775015b38dec2bc2965d482e903fdb4dbd293110a6
  [avbtool]=1aa6f2b462aa67aa3fdf488bee83ab517de8ad9d8228c7b45c35267ab2cf6781
)
AVB_KEY_SHA256=6a224754880a57ab9cbd308267cd157d94cf05a1c8cb851aec4090e045d24121
for t in mkbootimg mkdtboimg avbtool; do
  p=$(command -v "$t") || die "falta $t"
  [[ $(sha256sum < "$(readlink -f "$p")" | cut -d' ' -f1) == "${PIN[$t]}" ]] ||
    die "$t ($p) no coincide con el pin de toolchain.lock"
done
command -v lz4 >/dev/null || die "falta lz4"
command -v cpio >/dev/null || die "falta cpio"
[[ -f $AVB_KEY ]] || die "no hay clave AVB en $AVB_KEY"
[[ $(sha256sum < "$AVB_KEY" | cut -d' ' -f1) == "$AVB_KEY_SHA256" ]] || die "la clave AVB no es testkey_rsa4096.pem de AOSP"

IMAGE=$KOUT/arch/arm64/boot/Image
DTB=$KOUT/arch/arm64/boot/dts/$DTB_REL
DTC=$KOUT/scripts/dtc/dtc
[[ -f $IMAGE ]] || die "no hay $IMAGE: compila el kernel"
[[ -f $DTB ]] || die "no hay $DTB"
[[ -x $DTC ]] || die "no hay $DTC"

umask 022
[[ -n $OUT ]] || die "KOMODO_IMG_DIR vacia"; inside_work "$OUT" KOMODO_IMG_DIR
mkdir -p "$OUT"
[[ ! -L $OUT ]] || die "KOMODO_IMG_DIR es un enlace simbolico"
rm -f "$OUT"/*.img "$OUT"/*.cpio "$OUT"/*.lz4 "$OUT"/*.dtb "$OUT"/*.dtbo "$OUT"/SHA256SUMS "$OUT"/BUILDINFO

# --- DTB: exactamente las cuatro tuplas de /soc_compatible --------------------
say "DTB: comprobando /soc_compatible de $(basename "$DTB")"
"$DTC" -q -I dtb -O dts "$DTB" | python3 -I -c '
import re, sys
want = {"A0_FOPLP": (0x9875, 0, 0, 0), "A1_FOPLP": (0x9875, 0, 1, 0),
        "A0_IPOP": (0x9875, 0, 0, 1), "A1_IPOP": (0x9875, 0, 1, 1)}
src = sys.stdin.read()
m = re.search(r"\n\t(?:[A-Za-z_][A-Za-z0-9_]*: )*soc_compatible \{\n(.*?)\n\t\};", src, re.S)
if not m:
    sys.exit("no hay nodo /soc_compatible")
got = {}
for name, body in re.findall(r"\t\t(?:[A-Za-z_][A-Za-z0-9_]*: )*([^\s{};:]+) \{\n(.*?)\n\t\t\};", m.group(1), re.S):
    v = dict((k, int(x, 16)) for k, x in re.findall(r"(product_id|major|minor|pkg_mode) = <(0x[0-9a-f]+)>;", body))
    got[name] = tuple(v.get(k, -1) for k in ("product_id", "major", "minor", "pkg_mode"))
if got != want:
    sys.exit("soc_compatible: %r != %r" % (sorted(got.items()), sorted(want.items())))
print("    ok:", ", ".join(sorted(got)))
'
cp "$DTB" "$OUT/zumapro-komodo.dtb"
cat "$OUT/zumapro-komodo.dtb" > "$OUT/dtb.img"

# --- comunes ------------------------------------------------------------------
say "Kernel: Image.lz4 (lz4 -l -9, formato legacy)"
lz4 -l -9 -f -q "$IMAGE" "$OUT/Image.lz4"
: | cpio -o -H newc --quiet > "$OUT/empty.cpio"

# --- boot ---------------------------------------------------------------------
say "boot.img"
mkbootimg --header_version 4 --kernel "$OUT/Image.lz4" --cmdline '' --output "$OUT/boot.img"

# --- init_boot ----------------------------------------------------------------
say "init_boot.img"
mkbootimg --header_version 4 --ramdisk "$OUT/empty.cpio" \
  --os_version "$OS_VERSION" --os_patch_level "$OS_PATCH_LEVEL" --output "$OUT/init_boot.img"

# --- vendor_boot --------------------------------------------------------------
say "vendor_boot.img (cmdline: $VENDOR_CMDLINE)"
mkbootimg --header_version 4 --pagesize 0x800 --vendor_cmdline "$VENDOR_CMDLINE" \
  --ramdisk_type 1 --ramdisk_name '' --vendor_ramdisk_fragment "$OUT/empty.cpio" \
  --vendor_boot "$OUT/vendor_boot.img"

# --- vendor_kernel_boot -------------------------------------------------------
images=(boot init_boot vendor_boot dtbo)
if [[ -f $INITRAMFS ]]; then
  say "vendor_kernel_boot.img (initramfs $(basename "$INITRAMFS"))"
  # lz4 legacy: magic 02 21 4c 18
  [[ $(head -c4 "$INITRAMFS" | od -An -tx1 | tr -d ' \n') == 02214c18 ]] ||
    die "$INITRAMFS no es lz4 legacy (lz4 -l)"
  cp "$INITRAMFS" "$OUT/initramfs.cpio.lz4"
  mkbootimg --header_version 4 --pagesize 0x800 --vendor_cmdline '' \
    --dtb "$OUT/dtb.img" --ramdisk_type 1 --ramdisk_name '' \
    --vendor_ramdisk_fragment "$OUT/initramfs.cpio.lz4" \
    --vendor_boot "$OUT/vendor_kernel_boot.img"
  images=(boot init_boot vendor_boot vendor_kernel_boot dtbo)
else
  say "AVISO: no hay $INITRAMFS: vendor_kernel_boot.img NO se construye"
fi

# --- dtbo ---------------------------------------------------------------------
say "dtbo.img (id $DTBO_ID rev $DTBO_REV)"
grep -q "board_id = <$DTBO_ID>;" "$OVERLAY_SRC" || die "$OVERLAY_SRC: board_id no es $DTBO_ID"
grep -q "board_rev = <$DTBO_REV>;" "$OVERLAY_SRC" || die "$OVERLAY_SRC: board_rev no es $DTBO_REV"
"$DTC" -q -@ -I dts -O dtb -o "$OUT/komodo-board.dtbo" "$OVERLAY_SRC"
mkdtboimg create "$OUT/dtbo.img" --page_size=4096 --id="$DTBO_ID" --rev="$DTBO_REV" "$OUT/komodo-board.dtbo"

# --- pies AVB -----------------------------------------------------------------
for name in "${images[@]}"; do
  size=$((PART_SIZE[$name]))
  raw=$(stat -c %s "$OUT/$name.img")
  ((raw + 69632 < size)) || die "$name.img ($raw bytes) no cabe en $size con el pie"
  salt=$(sha256sum "$OUT/$name.img" | cut -d' ' -f1)
  say "AVB: $name.img -> $size bytes"
  avbtool add_hash_footer --image "$OUT/$name.img" --partition_name "$name" \
    --partition_size "$size" --algorithm SHA256_RSA4096 --key "$AVB_KEY" --salt "$salt" \
    --rollback_index "$AVB_ROLLBACK_INDEX" \
    --prop "com.android.build.$name.os_version:${OS_VERSION%%.*}" \
    --prop "com.android.build.$name.security_patch:$AVB_SECURITY_PATCH"
  [[ $(stat -c %s "$OUT/$name.img") -eq $size ]] || die "$name.img no mide $size"
done

{
  echo "kernel.release: $(cat "$KOUT/include/config/kernel.release" 2>/dev/null || echo '?')"
  head -1 "$KOUT/toolchain.txt" 2>/dev/null || true
  echo "vendor_cmdline: $VENDOR_CMDLINE"
  echo "avbtool: $(avbtool version)"
  echo "images: ${images[*]}"
} > "$OUT/BUILDINFO"
(cd "$OUT" && sha256sum ./*.img > SHA256SUMS)
ls -l "$OUT"/*.img
say "Hecho. Verificacion offline: scripts/verify-images.sh"
