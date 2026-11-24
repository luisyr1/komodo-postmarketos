#!/bin/bash
# SPDX-License-Identifier: MIT
# Logic adapted from Omamobile (bin/omamobile cmd_initramfs), MIT License,
# Copyright (c) 2026 Derek Ross and Omamobile contributors. The /init packed
# into the initramfs is Omamobile's own file (MIT), copied unmodified.
#
# mkinitramfs.sh - "ram-rescue" initramfs for the first komodo boot
# (Milestone 1). Downloads nothing; see scripts/README.md for the inputs.
#
# mkinitramfs.sh - initramfs "ram-rescue" para el primer arranque del komodo,
# equivalente a `omamobile initramfs` (bin/omamobile cmd_initramfs) sin Docker,
# sin sudo y sin ejecutar nada de Omamobile: solo tar, cpio y lz4 del host.
#
# Contenido:
#   - Alpine minirootfs 3.24.2 aarch64 (busybox + musl): sh y todos los applets
#     que usa el init (mount, ip, setsid, getty, blockdev, sed, grep, ...)
#   - dropbear y sus dependencias en .apk de Alpine v3.24 (ssh por USB NCM)
#   - /init = copia literal de omamobile/initramfs/init (commit 15a7d20)
#   - /etc/omamobile-*: modo ram-rescue, compatible google,zumapro-komodo,
#     producto USB, SIN lista de escritura UFS (=> todo el UFS en solo lectura)
#   - /root/.ssh/authorized_keys = tipo y clave de $KOMODO_PUBKEY (una clave
#     ssh-ed25519 dedicada), sin el comentario (suele llevar usuario@host)
# Se podan apk-tools y OpenSSL. No lleva kexec-tools ni e2fsprogs (solo se usan
# fuera de ram-rescue), ni devmem/reboot-to/bootctl (el init no los usa en este
# modo), ni splash.
#
# Entradas (descargadas y verificadas a mano; ver scripts/README.md):
#   KOMODO_MINIROOTFS  alpine-minirootfs-3.24.2-aarch64.tar.gz
#               SHA-256 fijado abajo (el mismo que bin/omamobile)
#   KOMODO_APK_DIR *.apk (dropbear, utmps-libs, skalibs-libs; musl y zlib ya
#               vienen en el minirootfs) + SHA256SUMS con el hash de cada uno;
#               comprobar antes su C: (Q1 sha1) contra el APKINDEX v3.24
#               firmado (clave 616ae350)
#   KOMODO_PUBKEY, KOMODO_OMAMOBILE_DIR, KOMODO_INIT_SRC: ver scripts/README.md
# Salida: $KOMODO_INITRAMFS_WORK/initramfs.cpio.lz4 (dentro de KOMODO_WORK);
# reproducible: orden LC_ALL=C, owner 0:0, mtime SOURCE_DATE_EPOCH o fijo,
# cpio --reproducible, lz4 -l -9.
set -euo pipefail

: "${KOMODO_WORK:?set KOMODO_WORK to your private work directory}"
die() { printf 'error: %s\n' "$*" >&2; exit 1; }
say() { printf '==> %s\n' "$*"; }
REPO=$(cd "$(dirname "$0")/.." && pwd -P)
[[ -d $KOMODO_WORK ]] || die "KOMODO_WORK no es un directorio"
case "$(cd "$KOMODO_WORK" && pwd -P)/" in "$REPO"/*) die "KOMODO_WORK no puede estar dentro del repositorio" ;; esac
# Toda ruta que se escribe o se borra tiene que quedar DENTRO de KOMODO_WORK
inside_work() { # ruta nombre-de-variable
  [[ -n $1 ]] || die "$2 esta vacia"
  case "$(realpath -m -- "$1")/" in
    "$(realpath -- "$KOMODO_WORK")"/?*) ;;
    *) die "$2=$1 queda fuera de KOMODO_WORK" ;;
  esac
}

O=${KOMODO_OMAMOBILE_DIR:-$KOMODO_WORK/src/omamobile}
MINIROOTFS=${KOMODO_MINIROOTFS:-$KOMODO_WORK/downloads/alpine/alpine-minirootfs-3.24.2-aarch64.tar.gz}
MINIROOTFS_SHA256=9bf70a7f18ea44094cbb5f70c58f9af129c8214745743db0e68e5502cc2ce773
APK_DIR=${KOMODO_APK_DIR:-$KOMODO_WORK/downloads/alpine/apks}
PUBKEY=${KOMODO_PUBKEY:-$KOMODO_WORK/keys/komodo_initramfs_ed25519.pub}
INIT_SRC=${KOMODO_INIT_SRC:-$O/initramfs/init}
# /init auditado (omamobile 15a7d20, revision 2026-11-24): si cambia, se para
INIT_SHA256=88f4b43eeb34664f8ba52832b06f0ec5cd308918be57ba337479b110ff499301
WORK=${KOMODO_INITRAMFS_WORK:-$KOMODO_WORK/build/initramfs}
inside_work "$WORK" KOMODO_INITRAMFS_WORK
STAGE=$WORK/stage
OUTF=$WORK/initramfs.cpio.lz4
inside_work "$STAGE" STAGE

umask 022
[[ -f $INIT_SRC ]] || die "no hay init en $INIT_SRC"
[[ $(sha256sum < "$INIT_SRC" | cut -d' ' -f1) == "$INIT_SHA256" ]] || die "el init cambio"
[[ -f $PUBKEY ]] || die "no hay clave publica $PUBKEY"
[[ $(wc -l < "$PUBKEY") -eq 1 && $(cut -d' ' -f1 "$PUBKEY") == ssh-ed25519 ]] || die "$PUBKEY no es una sola clave ssh-ed25519"
mkdir -p "$WORK"
[[ ! -L $STAGE ]] || die "stage es un symlink"

missing=0
if [[ ! -f $MINIROOTFS ]]; then
  echo "FALTA: $MINIROOTFS" >&2; missing=1
else
  echo "$MINIROOTFS_SHA256  $MINIROOTFS" | sha256sum -c --quiet || die "minirootfs con hash distinto"
fi
if ! compgen -G "$APK_DIR/*.apk" >/dev/null || [[ ! -f $APK_DIR/SHA256SUMS ]]; then
  echo "FALTA: $APK_DIR/*.apk + SHA256SUMS (dropbear y dependencias)" >&2; missing=1
else
  (cd "$APK_DIR" && sha256sum -c --quiet SHA256SUMS) || die "algun .apk no coincide con SHA256SUMS"
  for a in "$APK_DIR"/*.apk; do grep -q " ${a##*/}\$" "$APK_DIR/SHA256SUMS" || die "${a##*/} no esta en SHA256SUMS"; done
fi

say "Preparando la parte propia (init, /etc, authorized_keys) en $STAGE"
[[ -n $STAGE ]] || die "STAGE vacia"; inside_work "$STAGE" STAGE
rm -rf "$STAGE" && mkdir -p "$STAGE"
if ((missing == 0)); then
  tar -xzf "$MINIROOTFS" -C "$STAGE" --no-same-owner
  for a in "$APK_DIR"/*.apk; do
    # GNU tar lee los tres flujos gzip concatenados del .apk; no se extraen
    # ni ejecutan sus scripts de instalacion
    tar -xzf "$a" -C "$STAGE" --no-same-owner --exclude='.PKGINFO' --exclude='.SIGN.*' --exclude='.*.sh' 2>/dev/null ||
      die "no se pudo desempaquetar $a"
  done
  # Poda: apk-tools y OpenSSL (~6 MB) solo los usan apk y ssl_client; ni el
  # init ni dropbear (libtomcrypt propio) los necesitan
  [[ -n $STAGE ]] || die "STAGE vacia"; inside_work "$STAGE" STAGE
  rm -rf "$STAGE/sbin/apk" "$STAGE"/usr/lib/libapk.so* "$STAGE"/usr/lib/libcrypto.so* \
    "$STAGE"/usr/lib/libssl.so* "$STAGE/usr/lib/ossl-modules" "$STAGE/usr/lib/engines-3" \
    "$STAGE/etc/ssl" "$STAGE/etc/ssl1.1" "$STAGE/usr/bin/ssl_client" "$STAGE/etc/apk" \
    "$STAGE/usr/share/apk" "$STAGE/lib/apk"
  [[ -x $STAGE/bin/busybox ]] || die "el minirootfs no trae /bin/busybox"
  [[ -x $STAGE/usr/sbin/dropbear ]] || die "los .apk no traen /usr/sbin/dropbear"
fi
install -m 755 "$INIT_SRC" "$STAGE/init"
mkdir -p "$STAGE/etc" "$STAGE/root/.ssh" "$STAGE/etc/dropbear"
printf '%s\n' omamobile-root > "$STAGE/etc/omamobile-root-label"
printf '%s\n' ram-rescue > "$STAGE/etc/omamobile-root-mode"
printf '%s\n' google,zumapro-komodo > "$STAGE/etc/omamobile-compatible"
printf '%s\n' "Pixel 9 Pro XL (M1)" > "$STAGE/etc/omamobile-usb-product"
# Sin /etc/omamobile-ufs-rw: el init deja TODAS las particiones en solo lectura.
# Sin /etc/omamobile-usb-recovery: vale "yes" (si el host no configura el
# gadget en 45 s, panic -> reinicio -> el ABL vuelve al slot A tras agotar los
# reintentos; que un panico descuente intentos no esta verificado).
# Solo tipo y clave: el comentario de la publica (usuario@host) no entra
cut -d' ' -f1,2 "$PUBKEY" > "$STAGE/root/.ssh/authorized_keys"
# Claves de host de dropbear: NO se empaquetan; `dropbear -R` las genera en RAM
# en la primera conexion de cada arranque.
for f in omamobile-ufs-rw omamobile-ufs-rw-luns omamobile-ufs-rw-slot omamobile-nfsroot \
         omamobile-simplefb-trig omamobile-bringup-probe omamobile-usb-switch omamobile-fb-wait; do
  [[ ! -e $STAGE/etc/$f ]] || die "/etc/$f no debe estar en este initramfs"
done
[[ ! -e $STAGE/lib/modules/omamobile/order ]] || die "no se cargan modulos en ram-rescue"
[[ -z $(ls -A "$STAGE/etc/dropbear") ]] || die "/etc/dropbear no esta vacio"
chmod 700 "$STAGE/root" "$STAGE/root/.ssh"
chmod 600 "$STAGE/root/.ssh/authorized_keys"

if ((missing)); then
  say "Stage preparado SIN binarios aarch64: faltan descargas (ver arriba). No se genera $OUTF"
  exit 2
fi

say "Empaquetando $OUTF"
epoch=${SOURCE_DATE_EPOCH:-1795467703}   # fecha de commit de ffd33b7
find "$STAGE" -exec touch -h -d "@$epoch" {} +
(cd "$STAGE" && find . | LC_ALL=C sort | cpio -o -H newc --owner=0:0 --reproducible --quiet) |
  lz4 -l -9 -q > "$OUTF"
ls -l "$OUTF"
sha256sum "$OUTF"
