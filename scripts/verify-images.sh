#!/bin/bash
# SPDX-License-Identifier: MIT
#
# Offline check of what mkimages.sh produces. Never touches a phone.
#
# verify-images.sh - verificacion OFFLINE de lo que produce mkimages.sh.
# No toca ningun telefono (sin fastboot/adb). Sale con error al primer fallo.
#   KOMODO_WORK=... scripts/verify-images.sh [DIR]
# DIR: por defecto $KOMODO_IMG_DIR o $KOMODO_WORK/build/images. Tambien lee
# KOMODO_KOUT y KOMODO_AVB_KEY (ver scripts/README.md). Su directorio temporal
# se crea DENTRO de KOMODO_WORK (no en TMPDIR) y se borra al salir.
set -euo pipefail
: "${KOMODO_WORK:?set KOMODO_WORK to your private work directory}"
REPO=$(cd "$(dirname "$0")/.." && pwd -P)
[[ -d $KOMODO_WORK ]] || { echo "error: KOMODO_WORK no es un directorio" >&2; exit 1; }
case "$(cd "$KOMODO_WORK" && pwd -P)/" in "$REPO"/*) echo "error: KOMODO_WORK no puede estar dentro del repositorio" >&2; exit 1 ;; esac
fail() { printf 'NO OK: %s\n' "$*" >&2; exit 1; }
ok() { printf 'ok   %s\n' "$*"; }
# Toda ruta que se escribe o se borra tiene que quedar DENTRO de KOMODO_WORK
inside_work() { # ruta nombre-de-variable
  [[ -n $1 ]] || fail "$2 esta vacia"
  case "$(realpath -m -- "$1")/" in
    "$(realpath -- "$KOMODO_WORK")"/?*) ;;
    *) fail "$2=$1 queda fuera de KOMODO_WORK" ;;
  esac
}
D=${1:-${KOMODO_IMG_DIR:-$KOMODO_WORK/build/images}}
KOUT=${KOMODO_KOUT:-$KOMODO_WORK/build/kernel-out}
AVB_KEY=${KOMODO_AVB_KEY:-$KOMODO_WORK/downloads/avb/testkey_rsa4096.pem}
T=$(mktemp -d "$(realpath -- "$KOMODO_WORK")/.verify-images.XXXXXX")
[[ -n $T ]] || fail "mktemp no devolvio ruta"; inside_work "$T" "directorio temporal"
trap '[[ -n $T ]] && inside_work "$T" "directorio temporal" && rm -rf -- "$T"' EXIT
# Specific to build CP4A.261105.040.A1 (= values from that build's stock
# vbmeta/footers). On any other build take them from the stock images actually
# installed; never use a rollback index higher than stock.
# Especifico del build CP4A.261105.040.A1 (= valores del vbmeta y los pies
# stock de ese build). Con cualquier otro build, tomalos de las imagenes stock
# realmente instaladas; nunca uses un rollback index mayor que el de stock.
declare -A SIZE=([boot]=67108864 [init_boot]=8388608 [vendor_boot]=67108864 [vendor_kernel_boot]=67108864 [dtbo]=16777216)
WANT_ROLLBACK=1793836800
WANT_OS_VERSION=17.0.0
WANT_PATCH_LEVEL=2026-11
WANT_SECURITY_PATCH=2026-11-05
WANT_DTBO_ID=00060806      # = 0x60806
WANT_DTBO_REV=00010000     # = 0x10000
TESTKEY_SHA1=2597c218aae470a130f61162feaae70afd97f011   # sha1 de la clave publica de testkey_rsa4096 (avbtool)

[[ -d $D && -f $D/SHA256SUMS ]] || fail "no hay $D/SHA256SUMS"
(cd "$D" && sha256sum -c --quiet SHA256SUMS) || fail "SHA256SUMS"
ok "SHA256SUMS"

checked=0
for n in boot init_boot vendor_boot vendor_kernel_boot dtbo; do
  f=$D/$n.img
  [[ -f $f ]] || { echo "--   $n.img no existe (omitido)"; continue; }
  [[ $(stat -c %s "$f") -eq ${SIZE[$n]} ]] || fail "$n.img no mide ${SIZE[$n]}"
  info=$(avbtool info_image --image "$f")
  grep -q "Algorithm: *SHA256_RSA4096" <<<"$info" || fail "$n: algoritmo"
  grep -q "Rollback Index: *$WANT_ROLLBACK\$" <<<"$info" || fail "$n: rollback index"
  grep -q "Partition Name: *$n\$" <<<"$info" || fail "$n: partition name"
  grep -q "Public key (sha1): *$TESTKEY_SHA1" <<<"$info" || fail "$n: no es la clave de prueba AOSP"
  grep -q "com.android.build.$n.os_version -> '${WANT_OS_VERSION%%.*}'" <<<"$info" || fail "$n: prop os_version"
  grep -q "com.android.build.$n.security_patch -> '$WANT_SECURITY_PATCH'" <<<"$info" || fail "$n: prop security_patch"
  avbtool verify_image --image "$f" --key "$AVB_KEY" >/dev/null 2>&1 || fail "$n: avbtool verify_image"
  checked=$((checked + 1))
  ok "$n.img: ${SIZE[$n]} bytes, pie AVB RSA4096 testkey, rollback $WANT_ROLLBACK, props, verify_image"
done

((checked > 0)) || fail "no hay ninguna imagen en $D"

u() { unpack_bootimg --boot_img "$D/$1.img" --out "$T/$1" > "$T/$1.txt" 2>&1; }
if [[ -f $D/boot.img ]]; then
  u boot
  grep -q "boot image header version: 4" "$T/boot.txt" || fail "boot: header"
  grep -q "ramdisk size: 0" "$T/boot.txt" || fail "boot: ramdisk no vacio"
  grep -q "os version: None" "$T/boot.txt" || fail "boot: os_version (stock no la lleva)"
  grep -qx "command line args: " "$T/boot.txt" || fail "boot: cmdline no vacia"
  cmp -s "$T/boot/kernel" "$D/Image.lz4" || fail "boot: kernel != Image.lz4"
  lz4 -dc "$T/boot/kernel" | cmp -s - "$KOUT/arch/arm64/boot/Image" || fail "boot: Image.lz4 no descomprime al Image compilado"
  ok "boot.img: v4, kernel = Image.lz4 (descomprime al Image), sin ramdisk, cmdline ''"
fi
if [[ -f $D/init_boot.img ]]; then
  u init_boot
  grep -q "boot image header version: 4" "$T/init_boot.txt" || fail "init_boot: header"
  grep -q "kernel_size: 0" "$T/init_boot.txt" || fail "init_boot: kernel"
  grep -q "os version: $WANT_OS_VERSION" "$T/init_boot.txt" || fail "init_boot: os_version"
  grep -q "os patch level: $WANT_PATCH_LEVEL" "$T/init_boot.txt" || fail "init_boot: patch level"
  [[ $(cpio -it --quiet < "$T/init_boot/ramdisk" | wc -l) -eq 0 ]] || fail "init_boot: ramdisk no vacio"
  ok "init_boot.img: v4, ramdisk cpio vacio, $WANT_OS_VERSION / $WANT_PATCH_LEVEL"
fi
if [[ -f $D/vendor_boot.img ]]; then
  u vendor_boot
  grep -q "vendor boot image header version: 4" "$T/vendor_boot.txt" || fail "vendor_boot: header"
  grep -q "page size: 0x00000800" "$T/vendor_boot.txt" || fail "vendor_boot: pagesize"
  grep -q "dtb size: 0" "$T/vendor_boot.txt" || fail "vendor_boot: lleva dtb"
  grep -q "type: 0x1" "$T/vendor_boot.txt" || fail "vendor_boot: ramdisk type"
  ok "vendor_boot.img: v4, 0x800, sin dtb, fragmento vacio type 1, cmdline: $(sed -n 's/^vendor command line args: //p' "$T/vendor_boot.txt")"
fi
if [[ -f $D/vendor_kernel_boot.img ]]; then
  u vendor_kernel_boot
  grep -q "vendor boot image header version: 4" "$T/vendor_kernel_boot.txt" || fail "vkb: header"
  grep -q "page size: 0x00000800" "$T/vendor_kernel_boot.txt" || fail "vkb: pagesize"
  grep -qx "vendor command line args: " "$T/vendor_kernel_boot.txt" || fail "vkb: cmdline"
  grep -q "type: 0x1" "$T/vendor_kernel_boot.txt" || fail "vkb: ramdisk type"
  cmp -s "$T/vendor_kernel_boot/dtb" "$D/dtb.img" || fail "vkb: dtb"
  cmp -s "$T/vendor_kernel_boot/vendor_ramdisk00" "$D/initramfs.cpio.lz4" || fail "vkb: initramfs"
  # listado completo antes de grep: con pipefail, grep -q cortaria la tuberia (SIGPIPE)
  lz4 -dc "$D/initramfs.cpio.lz4" | cpio -it --quiet > "$T/initramfs.list"
  grep -qx init "$T/initramfs.list" || fail "vkb: el initramfs no tiene /init"
  grep -qx root/.ssh/authorized_keys "$T/initramfs.list" || fail "vkb: falta authorized_keys"
  ! grep -qE '^etc/omamobile-(ufs-rw|nfsroot)' "$T/initramfs.list" || fail "vkb: el initramfs lleva lista de escritura UFS o nfsroot"
  ok "vendor_kernel_boot.img: v4, 0x800, cmdline '', dtb = dtb.img, ramdisk = initramfs con /init"
fi
if [[ -f $D/dtbo.img ]]; then
  raw=$(avbtool info_image --image "$D/dtbo.img" | sed -n 's/^Original image size: *\([0-9]*\) bytes/\1/p')
  head -c "$raw" "$D/dtbo.img" > "$T/dtbo.raw"
  mkdtboimg dump "$T/dtbo.raw" -o "$T/dtbo.txt" -b "$T/dtbo.dump"
  grep -q "dt_entry_count = 1" "$T/dtbo.txt" || fail "dtbo: entradas"
  grep -q "page_size = 4096" "$T/dtbo.txt" || fail "dtbo: page_size"
  grep -q "id = $WANT_DTBO_ID" "$T/dtbo.txt" || fail "dtbo: id"
  grep -q "rev = $WANT_DTBO_REV" "$T/dtbo.txt" || fail "dtbo: rev"
  "$KOUT/scripts/dtc/dtc" -q -I dtb -O dts "$T/dtbo.dump.0" | grep -q "board_id = <0x${WANT_DTBO_ID#000}>" || fail "dtbo: board_id dentro del overlay"
  ok "dtbo.img: 1 entrada, page 4096, id 0x${WANT_DTBO_ID#000} rev 0x${WANT_DTBO_REV#000}"
fi
echo "Todo verificado (offline)."
