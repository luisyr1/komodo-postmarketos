# device/

- `komodo-board-overlay.dts` — empty dtbo overlay carrying komodo's
  `board_id`/`board_rev` (0x60806 / 0x10000), so ABL finds a matching dtbo
  entry. Used by [`../scripts/mkimages.sh`](../scripts/mkimages.sh) in
  Milestone 1. GPL-2.0-only, derived from Omamobile's Pixel 9a overlay. /
  Overlay vacío con el `board_id`/`board_rev` de komodo, usado en el hito 1.

Future pmbootstrap packages (pmaports-style APKBUILDs), e.g.:

- `device-google-komodo/` — device package (deviceinfo, firmware hooks).
- `linux-google-zumapro/` (name to be decided) — kernel package based on the
  Omamobile kernel fork.

No vendor firmware blobs or partition dumps go here.
