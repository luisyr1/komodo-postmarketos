#!/bin/bash
# SPDX-License-Identifier: MIT
# Derived from scripts/mkimages.sh (same mkbootimg, mkdtboimg and AVB
# parameters; image layout adapted from Omamobile, MIT License, Copyright (c)
# 2026 Derek Ross and Omamobile contributors).
#
# Builds the five slot-B images (Milestone 2) to boot Nura/postmarketOS
# installed on userdata, from the output of `pmbootstrap export`, plus the
# sparse userdata image. Never calls fastboot or adb, downloads nothing and
# does not use sudo. See scripts/README.md and docs/MILESTONE-2.md.
#
# mkimages-pmos.sh - monta las cinco imagenes del slot B del Pixel 9 Pro XL
# (komodo) para arrancar Nura/postmarketOS instalado en userdata, a partir de
# lo que deja `pmbootstrap export`. Solo construye ficheros: este script NO
# contiene ni llama a fastboot ni a adb, y no usa sudo.
#
#   KOMODO_WORK=... scripts/mkimages-pmos.sh [EXPORT_DIR]
#   KOMODO_WORK=... KOMODO_EXTRA_CMDLINE="pmos.debug-shell" scripts/mkimages-pmos.sh
#
# Entradas (por defecto, bajo $KOMODO_WORK):
#   KOMODO_PMOS_EXPORT  pmos/export (o el argumento): lo que deja
#                       `pmbootstrap export` (enlaces al work dir de pmbootstrap)
#     vmlinuz           Image.lz4 (lz4 legacy) del paquete linux-google-zumapro
#     initramfs         initramfs de postmarketos-mkinitfs (zstd por defecto)
#     vendor_boot.img   de boot-deploy (generate_bootimg, v4): de aqui salen la
#                       cmdline de Nura (generate-kernel-cmdline +
#                       pmos_root_uuid/pmos_boot_uuid de /etc/fstab) y el DTB
#     google-komodo.img imagen GPT (sectores de 4096) con pmOS_boot+pmOS_root;
#                       opcional: si esta, se comprueba y se convierte a sparse
#   KOMODO_AVB_KEY      downloads/avb/testkey_rsa4096.pem (clave de prueba AOSP)
#   KOMODO_OVERLAY_SRC  device/komodo-board-overlay.dts del repositorio
#   KOMODO_DTC          dtc: $KOMODO_KOUT/scripts/dtc/dtc (el del kernel del
#                       hito 1, build/kernel-out) o, si no existe, el del PATH
#   KOMODO_EXTRA_CMDLINE  parametros extra al final de la vendor_cmdline
#                       (p. ej. pmos.debug-shell); vacio por defecto
#   KOMODO_INITRAMFS_FORMAT  lz4 (defecto: recomprime a lz4 legacy, el formato
#                       que arranco en el hito 1) | keep (tal cual lo hizo mkinitfs)
#   KOMODO_ROOTFS_NAME  google-komodo.img
#   KOMODO_USERDATA_BYTES  tamano de userdata (por defecto, el de nuestra
#                       unidad de 256 GB; ver docs/DEVICE.md)
# Salida (tiene que estar dentro de KOMODO_WORK; se vacia de *.img etc.):
#   KOMODO_PMOS_IMG_DIR build/images-pmos
# Herramientas del host: mkbootimg, mkdtboimg y avbtool con el mismo SHA-256
# que el pin de omamobile/tools/toolchain.lock (como mkimages.sh), mas
# unpack_bootimg, lz4, zstd, cpio, python3, img2simg, simg2img.
#
# Lo que el ABL hace con esto (hito 1 y hito 2, verificado en nuestra unidad):
#   boot                v4, kernel = vmlinuz, cmdline ''
#   init_boot           v4, ramdisk vacio, os_version 17.0.0, patch 2026-11
#   vendor_boot         v4, pagesize 0x800, vendor_cmdline = la de Nura
#                       (+ KOMODO_EXTRA_CMDLINE), un fragmento vacio (type 1)
#   vendor_kernel_boot  v4, pagesize 0x800, vendor_cmdline '', DTB del
#                       paquete, fragmento = initramfs de Nura (type 1)
#   dtbo                overlay vacio id 0x60806 rev 0x10000
#   El ABL antepone los bootargs del DTB, quita todo console= y anade los
#   suyos (androidboot.*, console=null, bootconfig con slot_suffix).
#   Pie AVB en las cinco como mkimages.sh (SHA256_RSA4096, testkey, rollback
#   1793836800, props os_version 17 y security_patch 2026-11-05).
set -euo pipefail

: "${KOMODO_WORK:?set KOMODO_WORK to your private work directory}"
REPO=$(cd "$(dirname "$0")/.." && pwd -P)
[[ -d $KOMODO_WORK ]] || { echo "error: KOMODO_WORK no es un directorio" >&2; exit 1; }
case "$(cd "$KOMODO_WORK" && pwd -P)/" in "$REPO"/*) echo "error: KOMODO_WORK no puede estar dentro del repositorio" >&2; exit 1 ;; esac
die() { printf 'error: %s\n' "$*" >&2; exit 1; }
say() { printf '==> %s\n' "$*"; }
magic() { head -c4 "$1" | od -An -tx1 | tr -d ' \n'; }
# Toda ruta que se escribe o se borra tiene que quedar DENTRO de KOMODO_WORK
inside_work() { # ruta nombre-de-variable
  [[ -n $1 ]] || die "$2 esta vacia"
  case "$(realpath -m -- "$1")/" in
    "$(realpath -- "$KOMODO_WORK")"/?*) ;;
    *) die "$2=$1 queda fuera de KOMODO_WORK" ;;
  esac
}

EXPORT=${1:-${KOMODO_PMOS_EXPORT:-$KOMODO_WORK/pmos/export}}
OUT=${KOMODO_PMOS_IMG_DIR:-$KOMODO_WORK/build/images-pmos}
inside_work "$OUT" KOMODO_PMOS_IMG_DIR
AVB_KEY=${KOMODO_AVB_KEY:-$KOMODO_WORK/downloads/avb/testkey_rsa4096.pem}
OVERLAY_SRC=${KOMODO_OVERLAY_SRC:-$REPO/device/komodo-board-overlay.dts}
KOUT=${KOMODO_KOUT:-$KOMODO_WORK/build/kernel-out}
if [[ -n ${KOMODO_DTC:-} ]]; then
  DTC=$KOMODO_DTC
elif [[ -x $KOUT/scripts/dtc/dtc ]]; then
  DTC=$KOUT/scripts/dtc/dtc
else
  DTC=$(command -v dtc || true)
fi
EXTRA_CMDLINE=${KOMODO_EXTRA_CMDLINE:-}
INITRAMFS_FORMAT=${KOMODO_INITRAMFS_FORMAT:-lz4}
ROOTFS_NAME=${KOMODO_ROOTFS_NAME:-google-komodo.img}
DTB_NAME=zumapro-komodo.dtb

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
declare -A PART_SIZE=(
  [boot]=0x4000000
  [init_boot]=0x800000
  [vendor_boot]=0x4000000
  [vendor_kernel_boot]=0x4000000
  [dtbo]=0x1000000
)
# userdata: 239749204 KiB en nuestra unidad (modelo de 256 GB, docs/DEVICE.md)
USERDATA_BYTES=${KOMODO_USERDATA_BYTES:-$((239749204 * 1024))}
# vendor_boot: VENDOR_BOOT_ARGS_SIZE de bootimg.h
CMDLINE_MAX=2048

# --- herramientas (mismo pin que mkimages.sh / toolchain.lock de Omamobile) --
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
for t in unpack_bootimg lz4 zstd cpio python3 img2simg simg2img strings; do
  command -v "$t" >/dev/null || die "falta $t"
done
[[ -f $AVB_KEY ]] || die "no hay clave AVB en $AVB_KEY"
[[ $(sha256sum < "$AVB_KEY" | cut -d' ' -f1) == "$AVB_KEY_SHA256" ]] || die "la clave AVB no es testkey_rsa4096.pem de AOSP"
[[ -n $DTC && -x $DTC ]] || die "no hay dtc (pasa KOMODO_DTC=... o compila el kernel del hito 1)"
[[ -f $OVERLAY_SRC ]] || die "no hay $OVERLAY_SRC"
case $INITRAMFS_FORMAT in lz4 | keep) ;; *) die "KOMODO_INITRAMFS_FORMAT debe ser lz4 o keep" ;; esac
[[ $USERDATA_BYTES =~ ^[0-9]+$ ]] || die "KOMODO_USERDATA_BYTES no es un numero"
[[ -d $EXPORT ]] || die "no hay directorio de export $EXPORT (pmbootstrap export)"

umask 022
mkdir -p "$OUT"
[[ ! -L $OUT ]] || die "KOMODO_PMOS_IMG_DIR es un enlace simbolico"
# Directorio temporal DENTRO de KOMODO_WORK (no en TMPDIR); se borra al salir
T=$(mktemp -d "$(realpath -- "$KOMODO_WORK")/.mkimages-pmos.XXXXXX")
[[ -n $T ]] || die "mktemp no devolvio ruta"; inside_work "$T" "directorio temporal"
trap '[[ -n $T ]] && inside_work "$T" "directorio temporal" && rm -rf -- "$T"' EXIT
rm -f "$OUT"/*.img "$OUT"/*.cpio "$OUT"/*.lz4 "$OUT"/*.dtb "$OUT"/*.dtbo "$OUT"/initramfs* \
  "$OUT"/vmlinuz "$OUT"/cmdline.txt "$OUT"/SHA256SUMS "$OUT"/BUILDINFO "$OUT"/ROOTFS.raw.sha256
mkdir -p "$OUT/export"
[[ ! -L $OUT/export ]] || die "$OUT/export es un enlace simbolico"
rm -f "$OUT"/export/*

# --- copia de las entradas (export son enlaces al work dir de pmbootstrap) ---
for f in vmlinuz initramfs vendor_boot.img; do
  [[ -e $EXPORT/$f ]] || die "falta $EXPORT/$f (pmbootstrap export)"
  cp -L "$EXPORT/$f" "$OUT/export/$f"
done
(cd "$OUT/export" && sha256sum vmlinuz initramfs vendor_boot.img > SHA256SUMS.export)

# --- kernel ------------------------------------------------------------------
say "Kernel: $EXPORT/vmlinuz"
[[ $(magic "$OUT/export/vmlinuz") == 02214c18 ]] || die "vmlinuz no es lz4 legacy (lz4 -l)"
lz4 -dc "$OUT/export/vmlinuz" > "$T/Image" || die "vmlinuz no descomprime"
# Cabecera de Image arm64: "ARM\x64" en el desplazamiento 0x38
[[ $(dd if="$T/Image" bs=1 skip=56 count=4 status=none | od -An -tx1 | tr -d ' \n') == 41524d64 ]] ||
  die "vmlinuz no contiene una Image arm64"
cp "$OUT/export/vmlinuz" "$OUT/Image.lz4"
release=$(strings -n 8 "$T/Image" | sed -n 's/^Linux version \([^ ]*\) .*/\1/p' | head -n1 || true)
say "    kernel: ${release:-?}"

# --- vendor_boot.img de boot-deploy: cmdline, DTB, ramdisk --------------------
say "Desempaquetando vendor_boot.img de boot-deploy"
unpack_bootimg --boot_img "$OUT/export/vendor_boot.img" --out "$T/vb" > "$T/vb.txt"
grep -q "vendor boot image header version: 4" "$T/vb.txt" || die "vendor_boot de pmOS: no es v4"
grep -q "page size: 0x00000800" "$T/vb.txt" || die "vendor_boot de pmOS: pagesize != 0x800 (deviceinfo_flash_pagesize)"
PMOS_CMDLINE=$(sed -n 's/^vendor command line args: //p' "$T/vb.txt")
[[ -s $T/vb/dtb ]] || die "vendor_boot de pmOS sin DTB (deviceinfo_dtb)"
ramdisk=$(ls "$T/vb"/vendor_ramdisk* 2>/dev/null | head -n1) || true
[[ -n $ramdisk && -s $ramdisk ]] || die "vendor_boot de pmOS sin ramdisk"
cmp -s "$ramdisk" "$OUT/export/initramfs" || die "el ramdisk de vendor_boot.img no es el initramfs exportado (export desfasado?)"

# --- cmdline -------------------------------------------------------------------
VENDOR_CMDLINE=$(printf '%s %s' "$PMOS_CMDLINE" "$EXTRA_CMDLINE" | tr -s ' ' | sed 's/^ //; s/ $//')
say "cmdline (vendor_boot): $VENDOR_CMDLINE"
((${#VENDOR_CMDLINE} < CMDLINE_MAX)) || die "cmdline de ${#VENDOR_CMDLINE} bytes (max $((CMDLINE_MAX - 1)))"
for w in clk_ignore_unused pd_ignore_unused; do
  [[ " $VENDOR_CMDLINE " == *" $w "* ]] || die "falta $w en la cmdline (kernel-cmdline.conf del paquete)"
done
[[ " $VENDOR_CMDLINE " != *" console=null "* ]] || die "la cmdline lleva console=null"
if [[ " $VENDOR_CMDLINE " == *" pmos_root_uuid="* ]]; then
  say "    raiz por UUID (pmos_root_uuid presente)"
else
  say "    AVISO: sin pmos_root_uuid; el initramfs buscara la etiqueta pmOS_root"
fi
printf '%s\n' "$VENDOR_CMDLINE" > "$OUT/cmdline.txt"

# --- DTB: exactamente las cuatro tuplas de /soc_compatible --------------------
say "DTB: comprobando /soc_compatible"
"$DTC" -q -I dtb -O dts "$T/vb/dtb" > "$T/dtb.dts"
python3 -I -c '
import re, sys
want = {"A0_FOPLP": (0x9875, 0, 0, 0), "A1_FOPLP": (0x9875, 0, 1, 0),
        "A0_IPOP": (0x9875, 0, 0, 1), "A1_IPOP": (0x9875, 0, 1, 1)}
src = open(sys.argv[1]).read()
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
' "$T/dtb.dts"
grep -q 'compatible = "google,zumapro-komodo"' "$T/dtb.dts" || die "el DTB no es google,zumapro-komodo"
# Variante A (parche 0003 de linux-google-zumapro): simpledrm sobre el
# framebuffer del ABL. El ABL quita los console= de la vendor_cmdline, pero
# los bootargs del DTB (fbcon, gs_decon.stage=1) se quedan.
grep -q 'bootargs = ".*gs_decon.stage=1 ' "$T/dtb.dts" ||
  say "    AVISO: el DTB no lleva los bootargs de la variante A (gs_decon.stage=1): falta el parche 0003?"
cp "$T/vb/dtb" "$OUT/$DTB_NAME"
cp "$OUT/$DTB_NAME" "$OUT/dtb.img"

# --- initramfs ---------------------------------------------------------------
m=$(magic "$OUT/export/initramfs")
case $m in
  28b52ffd) fmt=zstd ;;
  02214c18) fmt=lz4-legacy ;;
  04224d18) fmt=lz4-frame ;;
  1f8b*) fmt=gzip ;;
  *) die "initramfs con formato desconocido (magic $m)" ;;
esac
say "initramfs: $fmt ($(stat -c %s "$OUT/export/initramfs") bytes)"
case $fmt in
  zstd) zstd -dcq "$OUT/export/initramfs" > "$T/initramfs.cpio" ;;
  lz4-*) lz4 -dc "$OUT/export/initramfs" > "$T/initramfs.cpio" ;;
  gzip) gzip -dc "$OUT/export/initramfs" > "$T/initramfs.cpio" ;;
esac
cpio -it --quiet < "$T/initramfs.cpio" > "$T/initramfs.list"
for f in init init_functions.sh usr/share/deviceinfo/deviceinfo etc/unudhcpd.conf \
         usr/libexec/google-komodo-ufs-ro usr/lib/udev/rules.d/60-google-komodo-ufs-ro.rules; do
  grep -qx "$f" "$T/initramfs.list" || die "al initramfs le falta /$f"
done
grep -qE '^hooks/[0-9]+-device-google-komodo\.sh$' "$T/initramfs.list" || die "al initramfs le falta el hook de device-google-komodo"
if [[ $INITRAMFS_FORMAT == lz4 && $fmt != lz4-legacy ]]; then
  say "    recomprimiendo a lz4 legacy (lz4 -l -9), como el initramfs del hito 1"
  lz4 -l -9 -q -c "$T/initramfs.cpio" > "$OUT/initramfs.cpio.lz4"
  lz4 -dc "$OUT/initramfs.cpio.lz4" | cmp -s - "$T/initramfs.cpio" || die "la recompresion no es identica"
  INITRAMFS_IMG=$OUT/initramfs.cpio.lz4
else
  cp "$OUT/export/initramfs" "$OUT/initramfs.$fmt"
  INITRAMFS_IMG=$OUT/initramfs.$fmt
fi

: | cpio -o -H newc --quiet > "$OUT/empty.cpio"

# --- las cinco imagenes (parametros de scripts/mkimages.sh) -------------------
say "boot.img"
mkbootimg --header_version 4 --kernel "$OUT/Image.lz4" --cmdline '' --output "$OUT/boot.img"
say "init_boot.img"
mkbootimg --header_version 4 --ramdisk "$OUT/empty.cpio" \
  --os_version "$OS_VERSION" --os_patch_level "$OS_PATCH_LEVEL" --output "$OUT/init_boot.img"
say "vendor_boot.img"
mkbootimg --header_version 4 --pagesize 0x800 --vendor_cmdline "$VENDOR_CMDLINE" \
  --ramdisk_type 1 --ramdisk_name '' --vendor_ramdisk_fragment "$OUT/empty.cpio" \
  --vendor_boot "$OUT/vendor_boot.img"
say "vendor_kernel_boot.img"
mkbootimg --header_version 4 --pagesize 0x800 --vendor_cmdline '' \
  --dtb "$OUT/dtb.img" --ramdisk_type 1 --ramdisk_name '' \
  --vendor_ramdisk_fragment "$INITRAMFS_IMG" \
  --vendor_boot "$OUT/vendor_kernel_boot.img"
say "dtbo.img (id $DTBO_ID rev $DTBO_REV)"
grep -q "board_id = <$DTBO_ID>;" "$OVERLAY_SRC" || die "$OVERLAY_SRC: board_id no es $DTBO_ID"
grep -q "board_rev = <$DTBO_REV>;" "$OVERLAY_SRC" || die "$OVERLAY_SRC: board_rev no es $DTBO_REV"
"$DTC" -q -@ -I dts -O dtb -o "$OUT/komodo-board.dtbo" "$OVERLAY_SRC"
mkdtboimg create "$OUT/dtbo.img" --page_size=4096 --id="$DTBO_ID" --rev="$DTBO_REV" "$OUT/komodo-board.dtbo"

images=(boot init_boot vendor_boot vendor_kernel_boot dtbo)
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

# --- verificacion de lo construido (offline) ---------------------------------
say "Verificando"
for name in "${images[@]}"; do
  avbtool verify_image --image "$OUT/$name.img" --key "$AVB_KEY" > /dev/null 2>&1 || die "$name: avbtool verify_image"
done
unpack_bootimg --boot_img "$OUT/boot.img" --out "$T/b" > "$T/b.txt"
cmp -s "$T/b/kernel" "$OUT/Image.lz4" || die "boot: kernel distinto"
grep -q "ramdisk size: 0" "$T/b.txt" || die "boot: ramdisk no vacio"
unpack_bootimg --boot_img "$OUT/vendor_boot.img" --out "$T/v" > "$T/v.txt"
[[ $(sed -n 's/^vendor command line args: //p' "$T/v.txt") == "$VENDOR_CMDLINE" ]] || die "vendor_boot: cmdline distinta"
grep -q "dtb size: 0" "$T/v.txt" || die "vendor_boot: lleva dtb"
unpack_bootimg --boot_img "$OUT/vendor_kernel_boot.img" --out "$T/k" > "$T/k.txt"
grep -qx "vendor command line args: " "$T/k.txt" || die "vkb: cmdline no vacia"
cmp -s "$T/k/dtb" "$OUT/dtb.img" || die "vkb: dtb distinto"
cmp -s "$T/k/vendor_ramdisk00" "$INITRAMFS_IMG" || die "vkb: initramfs distinto"
say "    ok: AVB, kernel, cmdline, DTB e initramfs donde el ABL los espera"

# --- rootfs: GPT de 4096, pmOS_boot + pmOS_root, a sparse ----------------------
if [[ -e $EXPORT/$ROOTFS_NAME ]]; then
  R=$(readlink -f "$EXPORT/$ROOTFS_NAME")
  rsize=$(stat -c %s "$R")
  say "rootfs: $ROOTFS_NAME ($rsize bytes)"
  ((rsize <= USERDATA_BYTES)) || die "la imagen no cabe en userdata ($USERDATA_BYTES bytes)"
  ((rsize % 4096 == 0)) || die "la imagen no es multiplo de 4096"
  python3 -I - "$R" <<'PY'
import struct, sys
path = sys.argv[1]
SS = 4096
with open(path, "rb") as f:
    f.seek(SS)
    hdr = f.read(92)
    if hdr[:8] != b"EFI PART":
        sys.exit("no hay cabecera GPT en el LBA 1 con sectores de 4096 (deviceinfo_rootfs_image_sector_size)")
    lba_entries, n, esz = struct.unpack("<QII", hdr[72:88])
    f.seek(lba_entries * SS)
    raw = f.read(n * esz)
    parts = []
    for i in range(n):
        e = raw[i * esz:(i + 1) * esz]
        if e[:16] == b"\0" * 16:
            continue
        first, last = struct.unpack("<QQ", e[32:48])
        parts.append((first, last))
    if len(parts) != 2:
        sys.exit("se esperaban 2 particiones (boot + root), hay %d" % len(parts))
    labels = []
    for first, last in parts:
        f.seek(first * SS + 1024)
        sb = f.read(1024)
        if struct.unpack("<H", sb[0x38:0x3a])[0] != 0xEF53:
            sys.exit("particion en LBA %d no es ext2/3/4" % first)
        labels.append(sb[0x78:0x88].rstrip(b"\0").decode())
        print("    particion LBA %d-%d: ext*, etiqueta %s" % (first, last, labels[-1]))
    if sorted(labels) != ["pmOS_boot", "pmOS_root"]:
        sys.exit("etiquetas %r != pmOS_boot/pmOS_root" % labels)
PY
  say "    convirtiendo a sparse (img2simg)"
  img2simg "$R" "$OUT/google-komodo-sparse.img"
  simg2img "$OUT/google-komodo-sparse.img" "$T/check.img"
  cmp -s "$T/check.img" "$R" || die "la imagen sparse no reproduce la original"
  rm -f "$T/check.img"
  sha256sum "$R" | sed "s|  .*|  ./$ROOTFS_NAME (raw, en el work dir de pmbootstrap)|" > "$OUT/ROOTFS.raw.sha256"
else
  say "AVISO: no hay $EXPORT/$ROOTFS_NAME: sin imagen de userdata (pmbootstrap install sin --no-image)"
fi

{
  echo "kernel.release: ${release:-?}"
  echo "vendor_cmdline: $VENDOR_CMDLINE"
  echo "initramfs: export $fmt -> $(basename "$INITRAMFS_IMG")"
  echo "avbtool: $(avbtool version)"
  echo "images: ${images[*]}"
  echo "export:"
  sed 's/^/  /' "$OUT/export/SHA256SUMS.export"
} > "$OUT/BUILDINFO"
(cd "$OUT" && sha256sum ./*.img > SHA256SUMS)
ls -l "$OUT"/*.img
say "Hecho en $OUT. Siguiente paso: docs/MILESTONE-2.md (flash manual de las cinco _b y de userdata)."
