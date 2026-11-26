# Device / Dispositivo: Google Pixel 9 Pro XL (`komodo`)

Model-level data only. No serial numbers, IMEI, MAC addresses or other
unique identifiers belong in this repository.

Solo datos del modelo. Números de serie, IMEI, MAC u otros identificadores
únicos no deben entrar nunca en este repositorio.

## General

| Item | Value |
|---|---|
| Codename | `komodo` |
| SoC | Google Tensor G4 (`zumapro`) |
| Sibling on same SoC | Pixel 9a (`tegu`) |
| RAM | 16 GB |
| Storage | 256 GB UFS (our unit) |
| Page size | 4K |

## Boot chain / Cadena de arranque

| Item | Value |
|---|---|
| Slots | A/B, Virtual A/B |
| Dynamic partitions | `super` |
| Boot image header | v4 |
| Relevant partitions | `boot`, `init_boot`, `vendor_boot`, `vendor_kernel_boot`, `dtbo` |
| Kernel cmdline | **Verified on our unit** (bootloader `ripcurrentpro-17.0-16433847`): the ABL **does** append the `vendor_boot` cmdline. Final cmdline = DTB `/chosen/bootargs` + `vendor_cmdline` + parameters added by the bootloader (among them `exynos_drm.panel_name=google-km4.…` and `console=null`). This corrects the earlier third-party claim that ABL ignores it |
| Custom images + stock `vbmeta` | images with an AVB hash footer signed with AOSP's public test key boot with stock `vbmeta_b` and the bootloader unlocked (verified, Milestone 1) |
| Forced reboot to fastboot | hold **Power + Volume Down** (verified) |
| Reboot to fastboot from Linux | `reboot bootloader` with `syscon-reboot-mode` on the PMU (reboot reason in `SYSIP_DAT0`, PMU + 0x810, `0xfc` = bootloader) and `reboot=warm` (a cold PSCI reset clears the register); verified on our unit in Milestone 3, no extra slot retry spent |
| Virtualization | pKVM active on stock |
| `fastboot boot` (RAM boot) | reported not viable on `komodo` by third parties; not verified by us |

## Current state of our unit / Estado actual de nuestra unidad

As of 2026-11-24. / A fecha de 2026-11-24.

| Item | Value |
|---|---|
| Bootloader lock | **unlocked** (`fastboot flashing unlock`) |
| Verified boot state | orange |
| Active slot | A |
| Slot state | A successful; B not successful (see slots below) |
| Build (both slots) | Android 17 stable, `CP4A.261105.040.A1`, security patch 2026-11-05 |
| Bootloader (both slots) | `ripcurrentpro-17.0-16433847` |
| Baseband | `g5400c-260818-261007-B-16536938` |
| Automatic system updates | disabled |
| Linux flashed | "display A" kernel variant images on the five slot-B boot partitions since 2026-11-24 (re-flashed 2026-11-25), replacing the Milestone 1 ones (`vbmeta_b` stock); restoring them to stock not recorded yet |

*Later note (2026-11-25): the active slot is now B, with Nura (Phosh UI,
Milestone 3) on `userdata` and the five slot-B images built from it; since
Milestone 4, `boot_b`, `vendor_boot_b` and `vendor_kernel_boot_b` carry the
`pkgrel=3` kernel (WiFi), since Milestone 5 the `pkgrel=4` kernel
(Bluetooth), and since Milestone 6 the `pkgrel=6` kernel (experimental
audio); since 2026-11-26 the `pkgrel=7` kernel, and slot B is marked
successful ([SLOT-B.md](SLOT-B.md)). See [STATUS.md](STATUS.md). / Nota posterior: el slot activo es ahora B, con
Nura (UI Phosh, hito 3) en `userdata`; desde el hito 4 `boot_b`,
`vendor_boot_b` y `vendor_kernel_boot_b` llevan el kernel `pkgrel=3` (WiFi),
desde el hito 5 el `pkgrel=4` (Bluetooth) y desde el hito 6 el `pkgrel=6`
(audio experimental), y desde el 2026-11-26 el `pkgrel=7`; el slot B está
marcado como correcto.*

Previous build (before 2026-11-24): Android Beta program, Android 16, security
patch 2025-08. How we got here: [UNLOCK.md](UNLOCK.md).

Build anterior (antes del 2026-11-24): programa Android Beta, Android 16,
parche 2025-08. Cómo llegamos aquí: [UNLOCK.md](UNLOCK.md).

## AVB, dtbo and partitions / AVB, dtbo y particiones

From the factory image of `CP4A.261105.040.A1`, analysed on the host. /
De la imagen de fábrica de `CP4A.261105.040.A1`, analizada en el PC.

AVB (stock `vbmeta`):

| Partition | AVB descriptor |
|---|---|
| `boot` | chained partition, rollback location 2 |
| `init_boot` | chained partition, rollback location 4 |
| `dtbo` | hash descriptor |
| `vendor_boot` | hash descriptor |
| `vendor_kernel_boot` | hash descriptor |

Consequence: our own images need an AVB hash footer. Images with such a
footer (`SHA256_RSA4096`, AOSP test key, rollback index 1793836800, size =
partition size) booted with stock `vbmeta_b` and the bootloader unlocked
(verified, Milestone 1); booting without a footer was not tried. `vbmeta`
itself is never flashed. / Consecuencia: las imágenes propias necesitan pie
AVB. Con ese pie (clave de prueba de AOSP) y `vbmeta_b` stock, con el
bootloader desbloqueado, arrancaron (verificado, hito 1); sin pie no se ha
probado. `vbmeta` no se flashea nunca.

## Slots and retries / Slots e intentos

Observed on our unit during Milestone 1. / Observado en nuestra unidad en el
hito 1.

- `fastboot flash` of any `_b` partition sets `slot-successful:b=no`. /
  Flashear cualquier partición `_b` pone `slot-successful:b=no`.
- `fastboot set_active b` gives 3 retries (`slot-retry-count:b: 3`). /
  `set_active b` da 3 intentos.
- Our Linux never marks the slot as successful, so each boot of B spends a
  retry. After forced reboots used them up (`slot-retry-count:b=0`) the
  bootloader went back to `current-slot=a` by itself, and Android booted on A
  with its data intact. / Nuestro Linux nunca marca el slot como correcto;
  agotados los intentos por reinicios forzados, el bootloader volvió solo al
  slot A y Android arrancó con sus datos intactos.
  *Later note: since 2026-11-26 slot B is marked successful on our unit and
  `slot-retry-count:b` no longer drops ([SLOT-B.md](SLOT-B.md)). / Nota
  posterior: desde el 2026-11-26 el slot B está marcado como correcto y el
  contador ya no baja.*
- Not verified: how much of the counter a Linux panic consumes. / Sin
  verificar: cuánto del contador consume un pánico de Linux.
- `/proc/bootconfig` under Linux reports `slot_suffix` `"_b"`.

## Seen from Linux (Milestone 1) / Visto desde Linux (hito 1)

Kernel `7.3.0-rc6-omamobile-push1`, RAM-only. / Solo en RAM.

| Item | Value |
|---|---|
| UFS partitions detected | 62 (kept read-only, none mounted) |
| `MemTotal` | ~15.5 GiB |
| Watchdogs | two s3c2410, "watchdog inactive, reset disabled" |
| Framebuffer | none: no `simple-framebuffer` in the DT, only reserved `framebuffer@fac00000`; screen black |
| USB gadget | `1d6b:0104`, NCM + ACM |

Later, with the "display A" kernel variant (2026-11-24/25): `simple-framebuffer`
under `/chosen` on the bootloader framebuffer (`0xfac00000`, 1344x2992, stride
5376, `a8r8g8b8`), `/proc/fb` = `0 simpledrmdrmfb`, `fbcon` 84x93 characters,
text console visible on screen (confirmed by eye). See
[JOURNAL.md](JOURNAL.md). / Después, con la variante "display A": consola de
texto visible en pantalla (confirmado a ojo).

`dtbo` (Android 17): 60 entries. Our unit uses entry 34 (`dtbo_idx=34`): board
id `0x00060806`, rev `0x00010000`.

`vendor_kernel_boot`: 8 base DTBs: 4 `zuma` and 4 `zumapro` (product_id
`0x9875`) with `/soc_compatible` nodes for A0/A1, FOPLP and IPOP variants.

Partition sizes / Tamaños de partición:

| Partition | Size |
|---|---|
| `boot` | 64 MiB |
| `vendor_boot` | 64 MiB |
| `vendor_kernel_boot` | 64 MiB |
| `init_boot` | 8 MiB |
| `dtbo` | 16 MiB |
| `userdata` | ~228 GiB (single, not A/B) |

## Stock software (observed on the previous build) / Software de serie (observado en el build anterior)

Observed on the previous Android 16 Beta build; not re-checked on Android 17. /
Observado en el build anterior (Android 16 Beta); sin revisar en Android 17.

| Item | Value |
|---|---|
| Kernel | GKI android14-6.1 |
| Vendor modules | 328 |

## Components seen on stock / Componentes vistos en stock

| Function | Part / driver |
|---|---|
| Display panel | `google-km4`, as named by the bootloader (`exynos_drm.panel_name=google-km4.…`, verified on our unit); Android loaded the module `panel_boe_nt37290` on the previous stock build; a third-party bring-up names it `google,gs-km4` in Google's device tree |
| Touchscreen | Synaptics S3908 over SPI, TouchComm (stock DTBO: `synaptics,tcm-spi` on `spi_20` = `spi@111d0000`, firmware suffix `S3908TG`); Android module `syna_touch` |
| WiFi / Bluetooth | Broadcom BCM4390 combo, WiFi 7 + Bluetooth (`bcmdhd4390`); WiFi on PCIe (`pcie_1`), ID `14e4:4438` (stock module aliases and our board DTS); Bluetooth on the APM UART (`serial@155d0000`, stock DTBO), firmware `BCM_200.hcd` in stock |
| GPU | Arm Mali-G715 (Mesa under Nura: "Mali-G715 MC7") |
| Charger / PMIC | MAX77779 family |
| Audio amplifiers | two Cirrus CS35L41 on `spi_19` (stock DTBO fragments 55–60): "L" (Top, also the earpiece) and "R" (Bottom); speaker-protection firmware `cs35l41-dsp1-spk-prot.wmfw` with per-side tunings in `vendor` |
| Microphones | three PDM microphones wired to the AoC (stock capture list `0,1,2`) |
| Haptics | Cirrus CS40L26 (`hsi2c_9`, 0x43) |
| Audio offload | AoC (Always-on Compute): all audio goes through it; firmware `aoc.bin`, release `16099865-polygon`, authenticated by the GSA and started through Trusty |
| Cameras | Front: Sony IMX858 (inferred: the stock camera HAL has a model ID function returning `0x0858`; ultra-wide and telephoto share the same stock codename). Main: a Samsung ISOCELL GN-series 50 MP sensor (the HAL's model ID is `0x08EF`; the exact commercial name is not settled). Read from the factory image only; no chip ID read on the phone yet |

Panel: the bootloader identifies it as `google-km4` (verified 2026-11-24);
`panel_boe_nt37290` was the module Android loaded. / Panel: el bootloader lo
identifica como `google-km4` (verificado el 2026-11-24); `panel_boe_nt37290`
era el módulo que cargaba Android.

Not yet verified: modem details, sensors, NFC and fingerprint parts, and
the camera sensors on the phone itself. / Sin verificar aún: módem,
sensores, NFC y huella, ni los sensores de cámara en el propio teléfono
(frontal Sony IMX858 y principal Samsung ISOCELL GN de 50 MP, deducidos del
HAL de cámara de la imagen de fábrica).

## Seen from Linux (Milestone 3) / Visto desde Linux (hito 3)

Kernel `7.3.0-rc6-zumapro` (`linux-google-zumapro` `pkgrel=2`), Nura with
Phosh, 2026-11-25. / Nura con Phosh.

| Item | Value |
|---|---|
| Display | `gs-decon` stage 2, real KMS, 1344x2992 at 60 Hz |
| Panel brightness | DCS `0x51` through DSIM0 (`gs-dsim-cmd`) with our minimal `google,km4` driver; backlight range 0..3271, 0 = pixel off |
| GPU | Mali-G715 on Panthor, CSF firmware `arm/mali/arch11.8/mali_csffw.bin`; OPP 150/302 MHz only; G3D relies on the bootloader leaving it powered (no power domain driver) |
| Fuel gauge | MAX77779 at `0x36` on `hsi2c6` (`i2c@108d0000`); design capacity read as 5035 mAh (shunt 2 mΩ assumed from the Pixel 9a) |
| Charger | MAX77779 at `0x69` on the same bus; input 500 mA from a PC USB port |
| USB-C controller | at `0x25` on the same bus; not enabled in our kernel |

Unique values (battery serials, MACs) are not recorded here. / Los valores
únicos (series de batería, MAC) no se anotan aquí.

## Seen from Linux (Milestone 4) / Visto desde Linux (hito 4)

Kernel `7.3.0-rc6-zumapro` (`linux-google-zumapro` `pkgrel=3`), 2026-11-25.
Procedure / Procedimiento: [MILESTONE-4.md](MILESTONE-4.md).

| Item | Value |
|---|---|
| WiFi chip | Broadcom BCM4390 (chip ID `0x4390`), WiFi 7 + Bluetooth combo |
| PCI | `0000:01:00.0`, `14e4:4438`, class `0x028000`, revision `0x05` |
| Chip revision | 5 = **b1** (Broadcom's naming: 0 = a0, 2 = b0, 5 = b1); `brcmfmac` reports `BCM4390/5` |
| PCIe host | `pcie_1` at `0x13120000` (`pcie_gs201`), root port `144d:eced`; PHY at `0x13160000` (`phy_zuma_pcie`) |
| Link | Gen3 x1 (8.0 GT/s), up at the first training attempt |
| Power / pins | `WL_REG_ON` = `gph3-4` (output, function 1 as in stock), the only power control (the module is fed from the system rail); PERST# `gph3-0`, CLKREQ `gph3-1` (stock DTBO) |
| DMA | 16 MiB `restricted-dma-pool` (`wifi-dma-pool`) in `0x80000000`–`0xc0000000`, assigned to the device |
| Device RAM | base `0x2a0000`, 3276800 bytes (`0x320000`); SYSMEM reports the same size |
| Firmware | `27.10.1121.57.30 (b1 release24)` from the factory image (`fw_bcmdhd.bin_4390_b1`), NVRAM of the USI module (`USI_G6BB_6327_V27`), CLM and TxCap blobs |
| Interface | `wlan0`, driver `brcmfmac`; bands 2.4 and 5 GHz used, 6 GHz not tried |

The NVRAM's `macaddr` is a template value (Broadcom's `00:90:4c` prefix),
not this unit's MAC. / El `macaddr` de la NVRAM es un valor de plantilla, no
la MAC de esta unidad.

## Seen from Linux (Milestone 5) / Visto desde Linux (hito 5)

Kernel `7.3.0-rc6-zumapro` (`linux-google-zumapro` `pkgrel=4`), 2026-11-25.
Procedure / Procedimiento: [MILESTONE-5.md](MILESTONE-5.md).

| Item | Value |
|---|---|
| Bluetooth chip | the Bluetooth half of the same BCM4390 combo; the ROM reports `BCM4390B1` (B1 silicon, matching the WiFi side), `chip id 200` |
| UART | USI1 of the APM, `serial@155d0000` (stock `serial_18`); under Linux `ttySAC0`, serdev controller `serial0`, child `serial0-0` |
| Driver | `hci_uart` (Broadcom protocol, `hci_bcm`) + `btbcm`; compatible `brcm,bcm4390-bt` with `brcm,bcm4389-bt` as fallback |
| Link speed | 3 Mbaud (stock uses 4 Mbaud; not tried) |
| Pins (stock DTBO) | `BT_REG_ON` `gpn8-0` behind a flip-flop clocked by `gpp24-3` (`brcm,ble-dbo`), `BT_DEV_WAKE` `gpn9-0`, `BT_HOST_WAKE` `gpa5-6` (rising edge, pulled down) |
| Power-on delay | `BT_REG_ON` held low 100 ms before raising it (stock HAL value; patch 0015) |
| Firmware | factory `BCM_200.hcd`, loaded as `brcm/BCM.google,zumapro-komodo.hcd`; ROM build `0000`, `0474` after the patch |
| Interface | `hci0`; BlueZ powers it; LE roles central and peripheral |
| Address | the chip's default address (generic, the same in every BCM4390 left unconfigured), not this unit's; the unit's real address has not been located |

No Bluetooth address of this unit or of any other device is recorded here. /
No se anota ninguna dirección Bluetooth de esta unidad ni de otros
dispositivos.

## Seen from Linux (Milestone 6) / Visto desde Linux (hito 6)

Kernel `7.3.0-rc6-zumapro` (`linux-google-zumapro` `pkgrel=6`), 2026-11-25.
Experimental. Procedure / Procedimiento: [MILESTONE-6.md](MILESTONE-6.md).

| Item | Value |
|---|---|
| Amplifiers | two Cirrus Logic CS35L41, ID `35a40`, revision **B2**, on `spi19` (`0x111c0000`, HSI0 USI1): Top on the native CS0, Bottom on GPIO CS `gpn1-0` |
| Amplifier pins (stock DTBO) | resets `gpp6-3` (Top), `gph2-1` (Bottom); interrupts `gpa5-5` (Top), `gpa7-2` (Bottom) |
| TDM 0 | 4 slots × 32 bit × 48 kHz, BCLK 6.144 MHz from the AoC; Top on slot 0, Bottom on slot 1 |
| Boost | peak current limited to 2.5 A by our DT (stock: 3.5 A); inductor and capacitor as stock |
| Trusty | answers (API version 5) once its modules are loaded; build string of the stock `ripcurrentpro` image |
| GSA | `16490000.gsa`, mailbox to Trusty; authenticates and loads the AoC image |
| AoC | `154b0000.aoc`, carve-out `0x94000000`–`0x96ffffff`, board id `0x40802` rev `0x10000` (`KM4`); firmware `16099865-polygon`, 94 services; starts once per boot (no reset) |
| Sound card | `google,komodo-aoc-snd-card` (id `googlekomodoaoc`): `EP1 playback` (device 0), `EP6 playback` (device 5), `EP1 capture` (device 8) |
| Driver limits | `Digital PCM Volume` 0..817, `Analog PCM Volume` 0..10 on both amplifiers (asking for 17 leaves 10) |
| EP6 | drops what was written before START, with no interrupt (same as the Pixel 8 Pro); patches 0022–0023 |
| Microphone 0 | `EP1 capture`, mono 48 kHz; the other two not tried |

No amplifier OTP values, calibration data or recordings are recorded here.
/ No se anotan valores OTP de los amplificadores, datos de calibración ni
grabaciones.

## Upstream status / Estado upstream

- pmaports/Nura: no `komodo` port; only gs101 (Pixel 6) in testing (as of
  2026-11-24 / a fecha 2026-11-24).
- Mainline Linux: no `zumapro` support (as of 2026-11-24 / a fecha
  2026-11-24).
- Working base: [linux-omarchy-mobile](https://github.com/derekross/linux-omarchy-mobile)
  (mainline 7.3-rc6 + Tensor, according to the fork's README), PR #276 adds `komodo` (depends on PR #273).
- Alternative reference: [Noxyntious/linux](https://github.com/Noxyntious/linux)
  branch `pixel9a`, `zumapro-komodo.dts` (not verified on hardware).
