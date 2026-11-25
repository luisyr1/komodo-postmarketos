#!/bin/bash
# SPDX-License-Identifier: MIT
#
# Stages the BCM4390 Wi-Fi firmware that YOU extracted from YOUR OWN factory
# image (vendor.img, /vendor/firmware) under the names brcmfmac asks for with
# kernel patch 0013, and copies it to the phone. Read docs/MILESTONE-4.md and
# docs/SAFETY.md first. NO WARRANTY.
#
# The firmware is proprietary (Broadcom/Google). This repository does not ship
# it and this script never downloads anything: it only checks, renames and
# copies files you already have. Never commit the staged files.
#
# install-wifi-firmware.sh - prepara el firmware WiFi del BCM4390 que TU has
# sacado de TU imagen de fabrica (vendor.img, /vendor/firmware) con los nombres
# que pide brcmfmac (parche 0013) y lo copia al telefono por SSH.
#
#   KOMODO_WORK=... scripts/install-wifi-firmware.sh --dry-run
#   KOMODO_WORK=... KOMODO_SSH_HOST=<user>@172.16.43.1 scripts/install-wifi-firmware.sh
#
# Options / Opciones:
#   --dry-run      check and stage inside KOMODO_WORK, copy nothing
#   --only-b1      only the b1 set (chip revision 5, the one our unit has)
#   --nvram-ref    Broadcom's reference-board NVRAM (bcmdhd.cal_4390_<rev>)
#                  instead of the USI module one (the default, see the doc)
#   --mac MAC      replace the template macaddr= of the staged NVRAMs with a
#                  locally administered unicast MAC (02:..., 06:..., ...)
#   --remove       delete /lib/firmware/updates/brcm/brcmfmac4390* on the phone
#
# Variables (all optional except KOMODO_WORK):
#   KOMODO_WIFI_FW_SRC     directory with the factory-named files
#                          [default $KOMODO_WORK/firmware/vendor-firmware]
#   KOMODO_WIFI_STAGE_DIR  staging directory, inside KOMODO_WORK; its
#                          brcmfmac4390* files are deleted and rebuilt
#                          [default $KOMODO_WORK/build/wifi-fw]
#   KOMODO_SSH_HOST        <user>@<address> of the phone (needed to copy/remove)
#   KOMODO_SSH_KEY         private key for ssh -i (otherwise ssh's defaults)
#
# Guarantees (checkable with grep):
#   - every factory file is checked against the SHA-256 pinned below before
#     it is staged; one mismatch aborts before anything is written.
#   - it writes only inside KOMODO_WIFI_STAGE_DIR (inside KOMODO_WORK) on the PC, and
#     only brcmfmac4390* under /lib/firmware/updates/brcm plus a temporary
#     tarball in the remote user's home on the phone.
#   - it does not touch modules, blacklists, boot partitions or fastboot.
#   - it does not print MAC addresses.
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

SRC=${KOMODO_WIFI_FW_SRC:-$KOMODO_WORK/firmware/vendor-firmware}
STAGE=${KOMODO_WIFI_STAGE_DIR:-$KOMODO_WORK/build/wifi-fw}
inside_work "$STAGE" KOMODO_WIFI_STAGE_DIR
case "$(realpath -m -- "$SRC")/" in "$REPO"/*) die "KOMODO_WIFI_FW_SRC cannot be inside the repository (proprietary files)" ;; esac
DEST=/lib/firmware/updates/brcm
BOARD=google,zumapro-komodo

only_b1=0; nvram_ref=0; mac=""; dry=0; remove=0
while (($#)); do
  case $1 in
    --only-b1) only_b1=1 ;;
    --nvram-ref) nvram_ref=1 ;;
    --mac) (($# >= 2)) || die "--mac needs an address"; shift; mac=$1 ;;
    --dry-run) dry=1 ;;
    --remove) remove=1 ;;
    -h|--help) sed -n '2,45p' "$0"; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
  shift
done

SSH_OPTS=(-o ConnectTimeout=10)
[[ -n ${KOMODO_SSH_KEY:-} ]] && SSH_OPTS+=(-i "$KOMODO_SSH_KEY" -o IdentitiesOnly=yes)
need_host() { [[ -n ${KOMODO_SSH_HOST:-} ]] || die "set KOMODO_SSH_HOST=<user>@<phone address>"; }

if ((remove)); then
  need_host
  say "remove $DEST/brcmfmac4390* on the phone"
  ((dry)) && { echo "(dry run: nothing removed)"; exit 0; }
  ssh -t "${SSH_OPTS[@]}" -- "$KOMODO_SSH_HOST" "sudo sh -c 'rm -f $DEST/brcmfmac4390*'"
  exit 0
fi

if [[ -n $mac ]]; then
  [[ $mac =~ ^[0-9a-fA-F]{2}(:[0-9a-fA-F]{2}){5}$ ]] || die "malformed MAC"
  first=$((16#${mac%%:*}))
  # bit 1 of the first octet = locally administered, bit 0 = multicast
  (((first & 3) == 2)) || die "use a locally administered unicast MAC (first octet x2, x6, xA or xE)"
fi

# SHA-256 of the factory files, from the public factory image of build
# CP4A.261105.040.A1 (vendor.img, /vendor/firmware). Other builds may ship
# other firmware: then these pins fail on purpose.
declare -A SHA=(
  [fw_bcmdhd.bin_4390_a0]=882b841c55b6e7f10bbcd016fd6713a58b1967d5ff96d9ae23e4891972885062
  [fw_bcmdhd.bin_4390_b0]=0ebe1021dd6824fe4b8c2ff74fa0488087b3f7a8577ee78fdafe35c361876ac4
  [fw_bcmdhd.bin_4390_b1]=f6876748f917c65e7a256b040cc5e341d7754ddc8760f948b411dbf8eb398529
  [bcmdhd.cal_4390_a0]=11b7d26e4f83210ffea9919e714868cca97f26fe1881a7ffbef7e9df27ace6ad
  [bcmdhd.cal_4390_b0]=8bbfb0b57ff870b6822fdbf40863f85c8b4b09def94a026eb92f772fc0ceb013
  [bcmdhd.cal_4390_b1]=226c3f62fca1071c6808a7eb3a90a864ed7d1872ecc63fa974255c228b57a637
  [bcmdhd.cal_USI_G6BB_6321_V21]=807a4e4d089971659252278e3a3032e2ac5e017035b11b10dd71333c91ab5869
  [bcmdhd.cal_USI_G6BB_6325_V25]=ba51698ff5ca402fbe0e576de8a9350011f9164159f7ef86878ecf08abfaae72
  [bcmdhd.cal_USI_G6BB_6327_V27]=eb63bfd7af479f036b38e36ca9a90e11bf745627d6e75e5870f8b426dce8353b
  [bcmdhd_clm.blob_4390_a0]=afd36e3d684617041f84dc8917524fb628a1f05fbd9cb2181c65daf0d4093c9a
  [bcmdhd_clm.blob_4390_b0]=1a717990c013d9c09ba42b27a70b56d6659f89918456f28e9a64d994e881b0ce
  [bcmdhd_clm.blob_4390_b1]=1a717990c013d9c09ba42b27a70b56d6659f89918456f28e9a64d994e881b0ce
  [bcmdhd_txcap.blob_4390_a0]=58d802d076e48dc73d24d334ac8a62c69b34a12fca853aa4fad993daf44b97bb
  [bcmdhd_txcap.blob_4390_b0]=6c257501583f41410069758a73ab559bc92f7c3c4951cc4c2ff8ed92973e3a8e
  [bcmdhd_txcap.blob_4390_b1]=6c257501583f41410069758a73ab559bc92f7c3c4951cc4c2ff8ed92973e3a8e
)
# NVRAM of the USI module per revision (the default) and of the reference board
declare -A NVRAM_USI=([b1]=bcmdhd.cal_USI_G6BB_6327_V27 [b0]=bcmdhd.cal_USI_G6BB_6325_V25 [a0]=bcmdhd.cal_USI_G6BB_6321_V21)
declare -A NVRAM_REF=([b1]=bcmdhd.cal_4390_b1 [b0]=bcmdhd.cal_4390_b0 [a0]=bcmdhd.cal_4390_a0)

REVS=(b1)
((only_b1)) || REVS+=(b0 a0)

# 1. Pick the pairs (factory name -> brcmfmac name) and check every hash
PAIRS=()
for rev in "${REVS[@]}"; do
  if ((nvram_ref)); then nv=${NVRAM_REF[$rev]}; else nv=${NVRAM_USI[$rev]}; fi
  base=brcmfmac4390$rev-pcie.$BOARD
  PAIRS+=("fw_bcmdhd.bin_4390_$rev:$base.bin" "$nv:$base.txt"
          "bcmdhd_clm.blob_4390_$rev:$base.clm_blob" "bcmdhd_txcap.blob_4390_$rev:$base.txcap_blob")
done
command -v sha256sum >/dev/null || die "sha256sum missing"
[[ -d $SRC ]] || die "KOMODO_WIFI_FW_SRC=$SRC is not a directory (extract the files first, see docs/MILESTONE-4.md)"
for p in "${PAIRS[@]}"; do
  f=${p%%:*}
  [[ -f $SRC/$f && ! -L $SRC/$f ]] || die "missing (or a link): $SRC/$f"
  got=$(sha256sum -- "$SRC/$f" | cut -d' ' -f1)
  [[ $got == "${SHA[$f]}" ]] || die "SHA-256 mismatch for $f (another build? then do not use these pins)"
done
say "factory files OK (${#PAIRS[@]} files, revisions: ${REVS[*]})"

# 2. Stage inside KOMODO_WORK
mkdir -p -- "$STAGE"
[[ ! -L $STAGE ]] || die "KOMODO_WIFI_STAGE_DIR is a link"
STAGE=$(realpath -- "$STAGE")
chmod 700 -- "$STAGE"
rm -f -- "$STAGE"/brcmfmac4390* "$STAGE/wifi-fw.tar" "$STAGE/SHA256SUMS"
for p in "${PAIRS[@]}"; do
  cp -- "$SRC/${p%%:*}" "$STAGE/${p#*:}"
done
if [[ -n $mac ]]; then
  for f in "$STAGE"/brcmfmac4390*.txt; do
    grep -q '^macaddr=' "$f" || die "no macaddr= line in $(basename "$f")"
    sed -i "s/^macaddr=.*/macaddr=$mac/" "$f"
  done
  say "macaddr= replaced in the staged NVRAMs (value not printed)"
fi
chmod 644 -- "$STAGE"/brcmfmac4390*
(cd "$STAGE" && sha256sum -- brcmfmac4390* > SHA256SUMS)
say "staged in $STAGE:"
(cd "$STAGE" && ls -l -- brcmfmac4390* | awk '{print "    " $5 "  " $NF}')
((dry)) && { echo "(dry run: nothing copied to the phone)"; exit 0; }

# 3. Copy: tarball to the user's home (no sudo), then extract as root with
#    a terminal for the sudo password, fixed owner and mode, and check.
need_host
(cd "$STAGE" && tar --owner=0 --group=0 --numeric-owner -cf wifi-fw.tar -- brcmfmac4390*)
say "copy to $KOMODO_SSH_HOST"
ssh "${SSH_OPTS[@]}" -- "$KOMODO_SSH_HOST" 'cat > "$HOME/.komodo-wifi-fw.tar"' < "$STAGE/wifi-fw.tar"
ssh -t "${SSH_OPTS[@]}" -- "$KOMODO_SSH_HOST" \
  "sudo sh -c 'mkdir -p $DEST && tar -x -o -f \"\$1\" -C $DEST && chown root:root $DEST/brcmfmac4390* && chmod 644 $DEST/brcmfmac4390*' sh \"\$HOME/.komodo-wifi-fw.tar\"; rm -f \"\$HOME/.komodo-wifi-fw.tar\""
ssh "${SSH_OPTS[@]}" -- "$KOMODO_SSH_HOST" "cd $DEST && sha256sum -c -" < "$STAGE/SHA256SUMS"
rm -f -- "$STAGE/wifi-fw.tar"
say "done; modules, blacklists and boot images were not touched"
