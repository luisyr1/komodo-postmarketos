#!/bin/bash
# SPDX-License-Identifier: MIT
#
# Writes the five Milestone 1 images to the _b partitions, and nothing else.
# Read docs/SAFETY.md and docs/MILESTONE-1.md first. NO WARRANTY.
#
# flash-slot-b.sh - escribe las CINCO imagenes de $KOMODO_IMG_DIR (por defecto
# $KOMODO_WORK/build/images, siempre dentro de KOMODO_WORK) en las particiones
# _b del Pixel 9 Pro XL (komodo) y no hace nada mas.
#
#   KOMODO_WORK=... scripts/flash-slot-b.sh --dry-run <SERIE>   solo comprobaciones + comandos
#   KOMODO_WORK=... scripts/flash-slot-b.sh <SERIE>             comprobaciones + flash _b
#
# <SERIE> es el numero de serie que imprime `fastboot devices`. Se pasa como
# argumento y no se guarda en ningun fichero.
#
# Garantias (revisables con grep):
#   - toda llamada a fastboot pasa por fb(), que solo admite
#     "devices", "-s <SERIE> getvar <var>" y "-s <SERIE> flash <p>_b <img>"
#     con <p> en la lista fija de cinco; cualquier otra cosa aborta.
#   - no cambia el slot activo, no reinicia, no borra, no toca el slot A.
#   - la unica aparicion de la palabra "update" es el nombre de la variable
#     de solo lectura snapshot-update-status (getvar).
#   - cada imagen tiene que llevar pie AVB (avbtool info_image) con el nombre
#     de su particion, SHA256_RSA4096 y el rollback index esperado; se exige
#     avbtool en el PATH (no basta con haber pasado verify-images.sh).
#   - el SHA-256 de cada imagen se recalcula justo antes de su flash y se
#     aborta si ya no es el de la comprobacion inicial.
#   - una variable inexistente (respuesta "Variable not found" o similar) se
#     distingue de cualquier otro error de fastboot, que aborta.
# Lo que viene despues (slot activo, arranque) lo hace el operador a mano:
# ver docs/MILESTONE-1.md.
set -euo pipefail

: "${KOMODO_WORK:?set KOMODO_WORK to your private work directory}"
REPO=$(cd "$(dirname "$0")/.." && pwd -P)
[[ -d $KOMODO_WORK ]] || { echo "error: KOMODO_WORK no es un directorio" >&2; exit 1; }
case "$(cd "$KOMODO_WORK" && pwd -P)/" in "$REPO"/*) echo "error: KOMODO_WORK no puede estar dentro del repositorio" >&2; exit 1 ;; esac

die() { printf '\nABORTADO: %s\n' "$*" >&2; exit 1; }
say() { printf '==> %s\n' "$*"; }
# Las rutas que usa este script tienen que quedar DENTRO de KOMODO_WORK
inside_work() { # ruta nombre-de-variable
  [[ -n $1 ]] || die "$2 esta vacia"
  case "$(realpath -m -- "$1")/" in
    "$(realpath -- "$KOMODO_WORK")"/?*) ;;
    *) die "$2=$1 queda fuera de KOMODO_WORK" ;;
  esac
}
IMG_DIR=${KOMODO_IMG_DIR:-$KOMODO_WORK/build/images}
inside_work "$IMG_DIR" KOMODO_IMG_DIR
[[ -d $IMG_DIR && ! -L $IMG_DIR ]] || die "KOMODO_IMG_DIR=$IMG_DIR no es un directorio (o es un enlace)"
IMG_DIR=$(realpath -- "$IMG_DIR")
PARTS=(boot init_boot vendor_boot vendor_kernel_boot dtbo)
# Specific to build CP4A.261105.040.A1 (= values from that build's stock
# vbmeta/footers). On any other build take them from the stock images actually
# installed; never use a rollback index higher than stock.
# Especifico del build CP4A.261105.040.A1 (= valores del vbmeta y los pies
# stock de ese build). Con cualquier otro build, tomalos de las imagenes stock
# realmente instaladas; nunca uses un rollback index mayor que el de stock.
declare -A SIZE=([boot]=0x4000000 [init_boot]=0x800000 [vendor_boot]=0x4000000
                 [vendor_kernel_boot]=0x4000000 [dtbo]=0x1000000)
WANT_PRODUCT=komodo
WANT_BL=ripcurrentpro-17.0-16433847
WANT_ROLLBACK=1793836800

DRY=0
case ${1:-} in
  --dry-run) DRY=1; shift ;;
  -*) die "opcion desconocida: $1" ;;
esac
(($# == 1)) || die "uso: $0 [--dry-run] <NUMERO_DE_SERIE>"
SERIAL=$1
[[ $SERIAL =~ ^[A-Za-z0-9]{6,32}$ ]] || die "numero de serie con forma rara"
command -v fastboot >/dev/null || die "no hay fastboot en el PATH"
command -v sha256sum >/dev/null || die "falta sha256sum"
command -v avbtool >/dev/null || die "falta avbtool (se usa para comprobar el pie AVB de cada imagen)"

is_part() { local p; for p in "${PARTS[@]}"; do [[ $1 == "$p" ]] && return 0; done; return 1; }

# Unica puerta a fastboot
fb() {
  if [[ $# -eq 1 && $1 == devices ]]; then
    fastboot devices
  elif [[ $# -eq 4 && $1 == -s && $2 == "$SERIAL" && $3 == getvar && $4 =~ ^[a-z0-9_:-]+$ ]]; then
    fastboot -s "$SERIAL" getvar "$4"
  elif [[ $# -eq 5 && $1 == -s && $2 == "$SERIAL" && $3 == flash && $4 == *_b ]] && is_part "${4%_b}" &&
       [[ $5 == "$IMG_DIR/${4%_b}.img" ]]; then
    fastboot -s "$SERIAL" flash "$4" "$5"
  else
    die "llamada a fastboot no permitida: $*"
  fi
}

# Lee una variable del bootloader en VAL. 0 = existe; 1 = el bootloader
# responde que no existe ("Variable not found", "unknown variable"...);
# cualquier otro error de fastboot (sin dispositivo, USB, etc.) aborta.
VAL=
read_var() {
  local out rc=0
  out=$(fb -s "$SERIAL" getvar "$1" 2>&1) || rc=$?
  out=${out//$'\r'/}
  out=${out//"$SERIAL"/<SERIE>}
  if ((rc == 0)) && grep -q "^\(([a-z]*) \)\{0,1\}$1:" <<<"$out"; then
    VAL=$(sed -n "s/^\(([a-z]*) \)\{0,1\}$1: *//p" <<<"$out" | head -n 1)
    return 0
  fi
  if grep -qiE 'variable not found|unknown variable|no such variable|variable does not exist' <<<"$out"; then
    VAL=
    return 1
  fi
  die "getvar $1: error de fastboot (codigo $rc): $(head -n 3 <<<"$out")"
}
# Valor de una variable que tiene que existir
getvar() {
  read_var "$1" || die "el bootloader no tiene la variable $1"
  printf '%s\n' "$VAL"
}
has_var() { read_var "$1"; }
expect() { # nombre valor-esperado
  local got
  got=$(getvar "$1")
  [[ $got == "$2" ]] || die "$1 = '${got}' (se esperaba '$2')"
  say "ok  $1 = $got"
}

say "Comprobaciones de las imagenes en $IMG_DIR"
[[ -f $IMG_DIR/SHA256SUMS ]] || die "no hay $IMG_DIR/SHA256SUMS"
declare -A HASH=()
for p in "${PARTS[@]}"; do
  f=$IMG_DIR/$p.img
  [[ -f $f && ! -L $f ]] || die "falta $f (o es un enlace)"
  want=$(awk -v n="./$p.img" '$2 == n || $2 == substr(n, 3) {print $1}' "$IMG_DIR/SHA256SUMS")
  [[ $want =~ ^[0-9a-f]{64}$ ]] || die "$p.img no esta (una sola vez) en SHA256SUMS"
  got=$(sha256sum < "$f" | cut -d' ' -f1)
  [[ $got == "$want" ]] || die "$p.img: SHA-256 $got != SHA256SUMS $want"
  [[ $(stat -c %s "$f") -eq $((SIZE[$p])) ]] || die "$p.img no mide ${SIZE[$p]}"
  info=$(avbtool info_image --image "$f" 2>&1) || die "$p.img: sin pie AVB legible (avbtool info_image)"
  grep -q "Partition Name: *$p\$" <<<"$info" || die "$p.img: el pie AVB no es de la particion $p"
  grep -q "Algorithm: *SHA256_RSA4096" <<<"$info" || die "$p.img: el pie AVB no es SHA256_RSA4096"
  grep -q "Rollback Index: *$WANT_ROLLBACK\$" <<<"$info" || die "$p.img: rollback index distinto de $WANT_ROLLBACK"
  HASH[$p]=$got
  say "ok  $p.img  $got  (pie AVB, rollback $WANT_ROLLBACK)"
done

say "Comprobaciones del telefono (fastboot del bootloader)"
mapfile -t devs < <(fb devices | awk 'NF {print $1}')
((${#devs[@]} == 1)) || die "hay ${#devs[@]} dispositivos fastboot (se exige exactamente uno)"
[[ ${devs[0]} == "$SERIAL" ]] || die "el dispositivo conectado no tiene la serie indicada"
say "ok  un unico dispositivo fastboot, con la serie indicada"
expect product "$WANT_PRODUCT"
expect is-userspace no
expect unlocked yes
expect version-bootloader "$WANT_BL"
slot=$(getvar current-slot); slot=${slot#_}
[[ $slot == a ]] || die "current-slot = '$slot' (se esperaba a)"
say "ok  current-slot = a"
expect slot-successful:a yes
expect slot-unbootable:a no
if has_var snapshot-update-status; then
  expect snapshot-update-status none
else
  say "--  snapshot-update-status no existe en este bootloader (se omite)"
fi
for p in "${PARTS[@]}"; do
  got=$(getvar "partition-size:${p}_b")
  [[ $got =~ ^0x[0-9a-fA-F]+$ ]] || die "partition-size:${p}_b = '$got'"
  (($((got)) == $((SIZE[$p])))) || die "partition-size:${p}_b = $got (se esperaba ${SIZE[$p]})"
  say "ok  partition-size:${p}_b = $got"
done

say "Comandos:"
for p in "${PARTS[@]}"; do
  printf '    fastboot -s <SERIE> flash %s_b %s\n' "$p" "$IMG_DIR/$p.img"
done
if ((DRY)); then
  say "--dry-run: no se ha escrito nada."
  exit 0
fi

read -r -p "Escribir las cinco particiones _b? Teclea FLASH-B para seguir: " ans
[[ $ans == FLASH-B ]] || die "cancelado por el operador"
for p in "${PARTS[@]}"; do
  # entre particiones: el mismo y unico telefono sigue ahi
  mapfile -t devs < <(fb devices | awk 'NF {print $1}')
  ((${#devs[@]} == 1)) && [[ ${devs[0]} == "$SERIAL" ]] || die "el dispositivo cambio antes de ${p}_b"
  # justo antes de escribir: la imagen sigue siendo la comprobada
  [[ -f $IMG_DIR/$p.img && ! -L $IMG_DIR/$p.img ]] || die "$p.img desaparecio o es un enlace"
  now=$(sha256sum < "$IMG_DIR/$p.img" | cut -d' ' -f1)
  [[ -n ${HASH[$p]:-} && $now == "${HASH[$p]}" ]] || die "$p.img cambio desde la comprobacion inicial ($now)"
  say "fastboot flash ${p}_b  ($now)"
  fb -s "$SERIAL" flash "${p}_b" "$IMG_DIR/$p.img"
done
say "Hecho: cinco particiones _b escritas. El slot activo NO se ha tocado."
say "Siguiente paso manual: docs/MILESTONE-1.md"
