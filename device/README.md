# device/

- `komodo-board-overlay.dts` — empty dtbo overlay carrying komodo's
  `board_id`/`board_rev` (0x60806 / 0x10000), so ABL finds a matching dtbo
  entry. Used by [`../scripts/mkimages.sh`](../scripts/mkimages.sh) in
  Milestone 1. GPL-2.0-only, derived from Omamobile's Pixel 9a overlay. /
  Overlay vacío con el `board_id`/`board_rev` de komodo, usado en el hito 1.

The pmbootstrap packages (pmaports-style APKBUILDs) live in
[`../pmaports/device/testing/`](../pmaports/device/testing/):

- `device-google-komodo/` — device package (deviceinfo, kernel cmdline,
  initramfs hook, UFS read-only guard, USB network and serial console). MIT.
- `linux-google-zumapro/` — kernel package based on the Omamobile kernel fork,
  with the "display A" patches. GPL-2.0-only.

Used in Milestone 2 ([../docs/MILESTONE-2.md](../docs/MILESTONE-2.md)). /
Paquetes de pmbootstrap, usados en el hito 2.

No vendor firmware blobs or partition dumps go here.
