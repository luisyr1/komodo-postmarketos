#!/bin/bash
# SPDX-License-Identifier: MIT
# Logic adapted from Omamobile (bin/omamobile cmd_kernel), MIT License,
# Copyright (c) 2026 Derek Ross and Omamobile contributors.
#
# build-kernel.sh - builds the komodo kernel: defconfig + omamobile.config
# fragment, Android clang r596125, LLVM=1 (like `omamobile kernel`, without a
# container). Downloads nothing. See scripts/README.md.
#
# Compila el kernel komodo: defconfig + omamobile.config (como bin/omamobile
# cmd_kernel, sin contenedor). No descarga nada.
set -euo pipefail

# Variables (todas opcionales salvo KOMODO_WORK; ver scripts/README.md):
#   KOMODO_KERNEL_SRC        arbol del kernel        (src/linux-ffd33b7)
#   KOMODO_KOUT              salida del build        (build/kernel-out) [dentro de KOMODO_WORK]
#   KOMODO_CLANG_DIR         clang r596125 extraido  (downloads/clang-r596125/tree)
#   KOMODO_OMAMOBILE_CONFIG  fragmento omamobile.config
#   KOMODO_SKIP_TOOLCHAIN_CHECK=1  salta (a proposito) el digest del arbol de clang
: "${KOMODO_WORK:?set KOMODO_WORK to your private work directory}"
die() { printf 'error: %s\n' "$*" >&2; exit 1; }
warn() { printf 'AVISO: %s\n' "$*" >&2; }
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

# Kernel tree: linux-omarchy-mobile, PR #276, commit
# ffd33b7ddc716eb3568fff9f8d337a4032d109eb (exported with git archive).
KERNEL_COMMIT=ffd33b7ddc716eb3568fff9f8d337a4032d109eb
# Digest "tree" de clang-r596125 extraido (= omamobile tools/toolchain.lock)
CLANG_TREE_DIGEST=111d4532e29ceb47cd6392ded7319c24d8ae5dd510b9a0770fc7bcb5d27a7881
SRC=${KOMODO_KERNEL_SRC:-$KOMODO_WORK/src/linux-ffd33b7}
OUT=${KOMODO_KOUT:-$KOMODO_WORK/build/kernel-out}
CLANG=${KOMODO_CLANG_DIR:-$KOMODO_WORK/downloads/clang-r596125/tree}
FRAG=${KOMODO_OMAMOBILE_CONFIG:-$KOMODO_WORK/src/omamobile/kernel/configs/omamobile.config}
inside_work "$OUT" KOMODO_KOUT

[[ -f $SRC/Makefile ]] || die "no hay arbol del kernel en KOMODO_KERNEL_SRC=$SRC"
[[ -x $CLANG/bin/clang ]] || die "no hay clang en KOMODO_CLANG_DIR=$CLANG"
[[ -f $FRAG ]] || die "no hay fragmento omamobile.config en KOMODO_OMAMOBILE_CONFIG=$FRAG"
# kernel/time/timeconst.bc necesita bc en el host
command -v bc >/dev/null || die "falta bc (instalalo con el gestor de paquetes del host)"

# Toolchain: digest del arbol de clang contra el pin, antes de compilar nada
if [[ ${KOMODO_SKIP_TOOLCHAIN_CHECK:-} == 1 ]]; then
  warn "KOMODO_SKIP_TOOLCHAIN_CHECK=1: NO se comprueba el digest de $CLANG"
  clang_check="skipped (KOMODO_SKIP_TOOLCHAIN_CHECK=1)"
else
  printf '==> %s\n' "Digest del arbol de clang (puede tardar)"
  got=$(python3 -I "$REPO/scripts/treedigest.py" "$CLANG") || die "treedigest.py fallo"
  [[ $got == "$CLANG_TREE_DIGEST" ]] ||
    die "el arbol de clang no coincide con el pin: $got != $CLANG_TREE_DIGEST (KOMODO_SKIP_TOOLCHAIN_CHECK=1 para saltarlo a proposito)"
  clang_check="tree digest $got (ok)"
fi
# Arbol del kernel: si es un checkout git, tiene que estar en el commit fijado.
# Exportado con git archive no lleva el commit: solo se avisa.
if [[ -e $SRC/.git ]]; then
  head=$(git -C "$SRC" rev-parse HEAD) || die "git no puede leer $SRC"
  [[ $head == "$KERNEL_COMMIT" ]] || die "el arbol del kernel esta en $head (se esperaba $KERNEL_COMMIT)"
  [[ -z $(git -C "$SRC" status --porcelain --untracked-files=no) ]] ||
    warn "el arbol del kernel tiene cambios locales sobre $KERNEL_COMMIT"
  printf '==> %s\n' "ok  arbol del kernel en $KERNEL_COMMIT"
else
  warn "$SRC no es un checkout git: no se puede comprobar que sea $KERNEL_COMMIT (comprueba tu git archive)"
fi

export PATH=$CLANG/bin:$PATH
# Identidad de build generica: la cadena "Linux version" no lleva usuario/host
# reales; fecha fija = fecha de commit de ffd33b7 (2026-11-23T16:01:43-05:00)
export KBUILD_BUILD_USER=builder KBUILD_BUILD_HOST=komodo KBUILD_BUILD_VERSION=1
export KBUILD_BUILD_TIMESTAMP="Mon Nov 23 21:01:43 UTC 2026"
export SOURCE_DATE_EPOCH=1795467703
M=(make -C "$SRC" ARCH=arm64 LLVM=1 O="$OUT")
mkdir -p "$OUT"
"${M[@]}" defconfig
(cd "$SRC" && scripts/kconfig/merge_config.sh -m -O "$OUT" "$OUT/.config" "$FRAG")
"${M[@]}" olddefconfig
"${M[@]}" -j"$(nproc)" Image dtbs modules
{ echo "clang: $("$CLANG/bin/clang" --version | sed -n 1p)"; echo "clang source: toolchain.lock clang-r596125, $clang_check"; } > "$OUT/toolchain.txt"
cat "$OUT/include/config/kernel.release"
