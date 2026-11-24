#!/bin/bash
# SPDX-License-Identifier: MIT
#
# Restores the five _b boot partitions to the stock images of build
# CP4A.261105.040.A1, and nothing else. Read docs/SAFETY.md first. NO WARRANTY.
#
# restore-slot-b-stock.sh - devuelve las CINCO particiones de arranque _b del
# Pixel 9 Pro XL (komodo) a las imagenes STOCK del build CP4A.261105.040.A1
# (el mismo que corre en el slot A) y no hace nada mas.
#
#   KOMODO_WORK=... scripts/restore-slot-b-stock.sh --dry-run <SERIE>
#   KOMODO_WORK=... scripts/restore-slot-b-stock.sh <SERIE>
#
# Imagenes: $KOMODO_STOCK_IMG_DIR (por defecto $KOMODO_WORK/stock/slot-b-stock,
# siempre dentro de KOMODO_WORK)/{boot,init_boot,vendor_boot,
# vendor_kernel_boot,dtbo}.img. Si faltan, se extraen del zip interno
# image-komodo-cp4a.261105.040.a1.zip de la imagen de fabrica oficial
# (KOMODO_STOCK_ZIP).
# Sus SHA-256 (de la imagen de fabrica publica, no de ninguna unidad) estan
# fijados abajo (extraidas y comprobadas el 2026-11-24).
#
# Garantias (revisables con grep):
#   - toda llamada a fastboot pasa por fb(), que solo admite
#     "devices", "-s <SERIE> getvar <var>" y "-s <SERIE> flash <p>_b <img>"
#     con <p> en la lista fija de cinco; cualquier otra cosa aborta.
#   - no cambia el slot activo, no reinicia, no borra, no toca el slot A.
#   - la unica aparicion de la palabra "update" es el nombre de la variable
#     de solo lectura snapshot-update-status (getvar).
#   - el SHA-256 de cada imagen se recalcula justo antes de su flash y se
#     aborta si ya no es el stock fijado.
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
# Toda ruta que se escribe o se borra tiene que quedar DENTRO de KOMODO_WORK
inside_work() { # ruta nombre-de-variable
  [[ -n $1 ]] || die "$2 esta vacia"
  case "$(realpath -m -- "$1")/" in
    "$(realpath -- "$KOMODO_WORK")"/?*) ;;
    *) die "$2=$1 queda fuera de KOMODO_WORK" ;;
  esac
}
IMG_DIR=${KOMODO_STOCK_IMG_DIR:-$KOMODO_WORK/stock/slot-b-stock}
inside_work "$IMG_DIR" KOMODO_STOCK_IMG_DIR
IMG_DIR=$(realpath -m -- "$IMG_DIR")
ZIP=${KOMODO_STOCK_ZIP:-$KOMODO_WORK/stock/image-komodo-cp4a.261105.040.a1.zip}
declare -A STOCK_SHA256=(
  [boot]=749c1800f195b0bae303f8abf12597e5963ebbe70840a57befda560216a9496d
  [init_boot]=f8d2b3547667ba8419d24bc58b30fd53d22e4757641468355d3ca50190b29097
  [vendor_boot]=7136ca53341d4c1965cbb2dd8a0314df2c8480be607fdd3a228a7b81918a8b18
  [vendor_kernel_boot]=6210a38afd641bcad28f27a7f85df3cb3395c2d87f720fdfee5f5e652730a19c
  [dtbo]=b8f370fa540c193e3e1b6dbcf61a3d05aaa12d749fbf86ec81fff0d275ddbed8
)
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

say "Comprobaciones de las imagenes stock en $IMG_DIR"
[[ ! -L $IMG_DIR ]] || die "$IMG_DIR es un enlace"
missing=()
for p in "${PARTS[@]}"; do [[ -f $IMG_DIR/$p.img ]] || missing+=("$p.img"); done
if ((${#missing[@]})); then
  [[ -f $ZIP ]] || die "faltan ${missing[*]} y no hay $ZIP"
  command -v unzip >/dev/null || die "falta unzip"
  say "Extrayendo ${missing[*]} de $(basename "$ZIP")"
  inside_work "$IMG_DIR" KOMODO_STOCK_IMG_DIR
  mkdir -p "$IMG_DIR"
  unzip -o -q -j "$ZIP" "${missing[@]}" -d "$IMG_DIR"
fi
inside_work "$IMG_DIR/SHA256SUMS" KOMODO_STOCK_IMG_DIR
(cd "$IMG_DIR" && for p in "${PARTS[@]}"; do sha256sum "$p.img"; done) > "$IMG_DIR/SHA256SUMS.new"
mv "$IMG_DIR/SHA256SUMS.new" "$IMG_DIR/SHA256SUMS"
for p in "${PARTS[@]}"; do
  f=$IMG_DIR/$p.img
  [[ -f $f && ! -L $f ]] || die "falta $f (o es un enlace)"
  want=${STOCK_SHA256[$p]}
  got=$(sha256sum < "$f" | cut -d' ' -f1)
  [[ $got == "$want" ]] || die "$p.img: SHA-256 $got != stock fijado $want"
  [[ $(stat -c %s "$f") -eq $((SIZE[$p])) ]] || die "$p.img no mide ${SIZE[$p]}"
  say "ok  $p.img  $got"
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

read -r -p "Restaurar las cinco particiones _b a stock? Teclea RESTAURAR-B para seguir: " ans
[[ $ans == RESTAURAR-B ]] || die "cancelado por el operador"
for p in "${PARTS[@]}"; do
  # entre particiones: el mismo y unico telefono sigue ahi
  mapfile -t devs < <(fb devices | awk 'NF {print $1}')
  ((${#devs[@]} == 1)) && [[ ${devs[0]} == "$SERIAL" ]] || die "el dispositivo cambio antes de ${p}_b"
  # justo antes de escribir: la imagen sigue siendo la stock fijada
  [[ -f $IMG_DIR/$p.img && ! -L $IMG_DIR/$p.img ]] || die "$p.img desaparecio o es un enlace"
  now=$(sha256sum < "$IMG_DIR/$p.img" | cut -d' ' -f1)
  [[ $now == "${STOCK_SHA256[$p]}" ]] || die "$p.img cambio desde la comprobacion inicial ($now)"
  say "fastboot flash ${p}_b  ($now)"
  fb -s "$SERIAL" flash "${p}_b" "$IMG_DIR/$p.img"
done
say "Hecho: cinco particiones _b de nuevo en stock CP4A.261105.040.A1. El slot activo NO se ha tocado."
say "Siguiente paso manual: docs/MILESTONE-1.md"
