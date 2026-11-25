#!/bin/bash
# SPDX-License-Identifier: MIT
#
# Stages the BCM4390 Bluetooth firmware that YOU extracted from YOUR OWN
# factory image (vendor.img, /vendor/firmware/brcm/BCM_200.hcd) under the name
# btbcm asks for with kernel patches 0014-0015, and copies it to the phone.
# Read docs/MILESTONE-5.md and docs/SAFETY.md first. NO WARRANTY.
#
# The firmware is proprietary (Broadcom/Google). This repository does not ship
# it and this script never downloads anything: it only checks, renames and
# copies a file you already have. Never commit the staged file.
#
# install-bt-firmware.sh - prepara el firmware Bluetooth del BCM4390 que TU
# has sacado de TU imagen de fabrica (vendor.img,
# /vendor/firmware/brcm/BCM_200.hcd) con el nombre que pide btbcm (parches
# 0014-0015) y lo copia al telefono por SSH.
#
#   KOMODO_WORK=... scripts/install-bt-firmware.sh --dry-run
#   KOMODO_WORK=... KOMODO_SSH_HOST=<user>@172.16.43.1 scripts/install-bt-firmware.sh
#
# Options / Opciones:
#   --dry-run   check and stage inside KOMODO_WORK, copy nothing
#   --alt       stage the factory BCM.hcd instead of BCM_200.hcd (a fallback
#               the stock configuration does not reference; never tried)
#   --remove    delete /lib/firmware/updates/brcm/BCM.google,zumapro-komodo.hcd
#               on the phone
#
# Variables (all optional except KOMODO_WORK):
#   KOMODO_BT_FW_SRC     directory with the factory-named .hcd files
#                        [default $KOMODO_WORK/firmware/vendor-firmware/brcm]
#   KOMODO_BT_STAGE_DIR  staging directory, inside KOMODO_WORK; its BCM.*.hcd
#                        file is deleted and rebuilt [default $KOMODO_WORK/build/bt-fw]
#   KOMODO_SSH_HOST      <user>@<address> of the phone (needed to copy/remove)
#   KOMODO_SSH_KEY       private key for ssh -i (otherwise ssh's defaults)
#
# Guarantees (checkable with grep):
#   - the factory file is checked against the SHA-256 pinned below before it
#     is staged; a mismatch aborts before anything is written.
#   - it writes only inside KOMODO_BT_STAGE_DIR (inside KOMODO_WORK) on the
#     PC, and only BCM.google,zumapro-komodo.hcd under
#     /lib/firmware/updates/brcm plus a temporary tarball in the remote
#     user's home on the phone.
#   - it does not touch modules, blacklists, boot partitions or fastboot.
#   - it does not read, print or set Bluetooth addresses.
set -euo pipefail

: "${KOMODO_WORK:?set KOMODO_WORK to your private work directory}"
REPO=$(cd "$(dirname "$0")/.." && pwd -P)
[[ -d $KOMODO_WORK ]] || { echo "error: KOMODO_WORK is not a directory" >&2; exit 1; }
case "$(cd "$KOMODO_WORK" && pwd -P)/" in "$REPO"/*) echo "error: KOMODO_WORK cannot be inside the repository" >&2; exit 1 ;; esac

die() { printf '\nABORTED: %s\n' "$*" >&2; exit 1; }
say() { printf '==> %s\n' "$*"; }
# Paths this script writes must resolve INSIDE KOMODO_WORK
inside_work() { # path variable-name
  [[ -n $1 ]] || die "$2 is empty"
  case "$(realpath -m -- "$1")/" in
    "$(realpath -- "$KOMODO_WORK")"/?*) ;;
    *) die "$2=$1 is outside KOMODO_WORK" ;;
  esac
}

SRC=${KOMODO_BT_FW_SRC:-$KOMODO_WORK/firmware/vendor-firmware/brcm}
STAGE=${KOMODO_BT_STAGE_DIR:-$KOMODO_WORK/build/bt-fw}
inside_work "$STAGE" KOMODO_BT_STAGE_DIR
case "$(realpath -m -- "$SRC")/" in "$REPO"/*) die "KOMODO_BT_FW_SRC cannot be inside the repository (proprietary files)" ;; esac
DEST=/lib/firmware/updates/brcm
# btbcm has no name for the BCM4390 in its table, so it asks for
# brcm/BCM.<root compatible>.hcd first, then brcm/BCM.hcd
NAME=BCM.google,zumapro-komodo.hcd

alt=0; dry=0; remove=0
while (($#)); do
  case $1 in
    --alt) alt=1 ;;
    --dry-run) dry=1 ;;
    --remove) remove=1 ;;
    -h|--help) sed -n '2,44p' "$0"; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
  shift
done

SSH_OPTS=(-o ConnectTimeout=10)
[[ -n ${KOMODO_SSH_KEY:-} ]] && SSH_OPTS+=(-i "$KOMODO_SSH_KEY" -o IdentitiesOnly=yes)
need_host() { [[ -n ${KOMODO_SSH_HOST:-} ]] || die "set KOMODO_SSH_HOST=<user>@<phone address>"; }

if ((remove)); then
  need_host
  say "remove $DEST/$NAME on the phone"
  ((dry)) && { echo "(dry run: nothing removed)"; exit 0; }
  ssh -t "${SSH_OPTS[@]}" -- "$KOMODO_SSH_HOST" "sudo rm -f '$DEST/$NAME'"
  exit 0
fi

# SHA-256 of the factory files, from the public factory image of build
# CP4A.261105.040.A1 (vendor.img, /vendor/firmware/brcm). Other builds may
# ship other firmware: then these pins fail on purpose.
declare -A SHA=(
  [BCM_200.hcd]=e716e8ef48865fa99f26a50bdaa1390c3bdca5688579845513e6b97341009ce5
  [BCM.hcd]=7c907205db9c9cae9ec704f534518a1cc892507ae7eac63fb772c660483ff3ee
)
if ((alt)); then f=BCM.hcd; else f=BCM_200.hcd; fi

# 1. Check the factory file
command -v sha256sum >/dev/null || die "sha256sum missing"
[[ -d $SRC ]] || die "KOMODO_BT_FW_SRC=$SRC is not a directory (extract the file first, see docs/MILESTONE-5.md)"
[[ -f $SRC/$f && ! -L $SRC/$f ]] || die "missing (or a link): $SRC/$f"
got=$(sha256sum -- "$SRC/$f" | cut -d' ' -f1)
[[ $got == "${SHA[$f]}" ]] || die "SHA-256 mismatch for $f (another build? then do not use these pins)"
say "factory file OK: $f"

# 2. Stage inside KOMODO_WORK
mkdir -p -- "$STAGE"
[[ ! -L $STAGE ]] || die "KOMODO_BT_STAGE_DIR is a link"
STAGE=$(realpath -- "$STAGE")
chmod 700 -- "$STAGE"
rm -f -- "$STAGE/$NAME" "$STAGE/bt-fw.tar" "$STAGE/SHA256SUMS"
cp -- "$SRC/$f" "$STAGE/$NAME"
chmod 644 -- "$STAGE/$NAME"
(cd "$STAGE" && sha256sum -- "$NAME" > SHA256SUMS)
say "staged in $STAGE:"
(cd "$STAGE" && ls -l -- "$NAME" | awk '{print "    " $5 "  " $NF}')
((dry)) && { echo "(dry run: nothing copied to the phone)"; exit 0; }

# 3. Copy: tarball to the user's home (no sudo), then extract as root with
#    a terminal for the sudo password, fixed owner and mode, and check.
need_host
(cd "$STAGE" && tar --owner=0 --group=0 --numeric-owner -cf bt-fw.tar -- "$NAME")
say "copy to $KOMODO_SSH_HOST"
ssh "${SSH_OPTS[@]}" -- "$KOMODO_SSH_HOST" 'cat > "$HOME/.komodo-bt-fw.tar"' < "$STAGE/bt-fw.tar"
ssh -t "${SSH_OPTS[@]}" -- "$KOMODO_SSH_HOST" \
  "sudo sh -c 'mkdir -p $DEST && tar -x -o -f \"\$1\" -C $DEST && chown root:root \"$DEST/$NAME\" && chmod 644 \"$DEST/$NAME\"' sh \"\$HOME/.komodo-bt-fw.tar\"; rm -f \"\$HOME/.komodo-bt-fw.tar\""
ssh "${SSH_OPTS[@]}" -- "$KOMODO_SSH_HOST" "cd $DEST && sha256sum -c -" < "$STAGE/SHA256SUMS"
rm -f -- "$STAGE/bt-fw.tar"
say "done; modules, blacklists and boot images were not touched"
