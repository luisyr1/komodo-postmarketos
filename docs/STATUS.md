# Hardware status / Estado del hardware

Last updated / Última actualización: 2026-11-25

## Device state / Estado del dispositivo

- Bootloader: **unlocked** (`verifiedbootstate` orange), active slot B (Nura).
- Both slots: stock Android 17, `CP4A.261105.040.A1` (patch 2026-11-05), same
  bootloader on both. Automatic system updates disabled.
- Linux: **Milestone 1 passed** (2026-11-24): mainline-based kernel booted
  from slot B, RAM-only. [MILESTONE-1.md](MILESTONE-1.md).
- Display: **text console on screen** since 2026-11-25 (confirmed by eye),
  with the "display A" kernel variant. [JOURNAL.md](JOURNAL.md).
- **Milestone 2 passed** (2026-11-25): Nura edge (console UI, systemd)
  installed on `userdata` and booted from slot B; kernel `7.3.0-rc6-zumapro`.
  Slot B holds the five images built by `mkimages-pmos.sh` (`vbmeta_b`
  stock); `vendor_boot_b` temporarily carries `pmos.debug-shell`. Android
  data on `userdata` was lost (expected); slot A, bootloader, radio and
  `vbmeta` untouched. [MILESTONE-2.md](MILESTONE-2.md).

- Bootloader: **desbloqueado** (`verifiedbootstate` orange), slot activo B (Nura).
- Ambos slots: Android 17 stock, `CP4A.261105.040.A1` (parche 2026-11-05),
  mismo bootloader en los dos. Actualizaciones automáticas desactivadas.
- Linux: **hito 1 superado** (2026-11-24): kernel de base mainline arrancado
  desde el slot B, solo en RAM.
- Pantalla: **consola de texto en pantalla** desde el 2026-11-25 (confirmado a
  ojo), con la variante de kernel "display A".
- **Hito 2 superado** (2026-11-25): Nura edge (UI de consola, systemd)
  instalado en `userdata` y arrancado desde el slot B; kernel
  `7.3.0-rc6-zumapro`. El slot B lleva las cinco imágenes de
  `mkimages-pmos.sh` (`vbmeta_b` stock); `vendor_boot_b` lleva de momento
  `pmos.debug-shell`. Los datos de Android en `userdata` se perdieron
  (esperado); slot A, bootloader, radio y `vbmeta`, sin tocar.

Details / Detalles: [DEVICE.md](DEVICE.md), [UNLOCK.md](UNLOCK.md).

## Legend / Leyenda

- **untested / sin probar**: not tried on our unit.
- **reported / reportado**: a third party reports it working on `komodo`; not reproduced by us.
- **disabled upstream / desactivado**: described in third-party DTS but disabled there.
- **works / funciona**, **partial / parcial**, **broken / roto**, **no output / sin salida**: verified on our unit.

Display: on our unit, with the PR #276 tree at commit `ffd33b7` as used in
Milestone 1, there is **no** display output, which qualifies the third-party
"reported". With our "display A" variant (`gs-decon` built in, a
`simple-framebuffer` node in `/chosen`, `gs_decon.stage=1`) the screen shows
the Linux text console (verified 2026-11-25), and Nura's `login:` prompt
(Milestone 2). The patches are published in
[`../pmaports/device/testing/linux-google-zumapro/`](../pmaports/device/testing/linux-google-zumapro/). / Pantalla: en nuestra unidad, con el árbol del PR #276 en
el commit `ffd33b7` tal como se usó en el hito 1, **no** hay salida de
pantalla, lo que matiza el "reported" de terceros. Con nuestra variante
"display A" (`gs-decon` integrado, nodo `simple-framebuffer` en `/chosen`,
`gs_decon.stage=1`) la pantalla muestra la consola de texto de Linux
(verificado el 2026-11-25) y el `login:` de Nura (hito 2). Los parches están
publicados en el paquete `linux-google-zumapro`.

Source for third-party reports / Fuente de los reportes de terceros:
Omamobile kernel PR #276 (`komodo` board, depends on PR #273), per its author.
<https://github.com/derekross/linux-omarchy-mobile> (renamed on GitHub to
`linux-omamobile`; the old URL redirects / renombrado en GitHub a
`linux-omamobile`; la URL antigua redirige)

| Component / Componente | Hardware (stock) | Our unit / Nuestra unidad | Third party / Terceros | Notes / Notas |
|---|---|---|---|---|
| Boot (slot B) | ABL, boot header v4 | **works** (slot B: RAM-only rescue and Nura on `userdata`) | reported (PR #276) | Milestone 1; "display A" images (2026-11-25, USB gadget at ~26 s); Milestone 2 (Nura; in the rehearsal without `userdata` the initramfs gadget came up at ~28 s). AVB hash footer with AOSP test key, `vbmeta_b` stock; ABL appends the `vendor_boot` cmdline (verified). **Every boot spends one of slot B's 3 retries** and nothing marks it successful; at 0 the ABL boots slot A. Workaround: `fastboot set_active b` beforehand. Unresolved |
| UFS storage | 256 GB UFS | **works**: `userdata` read-write, everything else read-only | reported (PR #276) | Milestone 2: udev/initramfs guard keeps every UFS partition except `userdata` read-only (`--check` = 0); the whole `sda` LUN stays writable by design (it holds `userdata`) |
| Root on userdata | — | **works** | reported (PR #276) | ext4 image (GPT with 4096-byte sectors, `pmOS_boot` + `pmOS_root`) on a loop device over `userdata`, grown to 221.6 GiB on first boot. Single `userdata`: stock Android reportedly reformats it (not verified by us) |
| USB gadget (NCM/ACM/SSH) | — | **works** | reported (PR #276) | `1d6b:0104`. Milestone 1: `172.16.42.0/24`, ~24 s. Nura: `172.16.43.0/24` (phone `.1`), PC-side MAC `02:6b:6f:6d:6f:01` (fixed, from `deviceinfo`). On Nura's first boot the PC did not enumerate it (errors `-71`); not repeated, cause unknown. Later "drops" were the PC losing its static IP on re-enumeration (fixed with a NetworkManager profile by MAC). With `pmos.debug-shell` the debug shell on `ttyGS0` is garbled (two readers); telnet works |
| Display | panel `google-km4` (bootloader name; see note) | **partial**: text console (`simpledrm` + `fbcon`, 84x93 characters) | reported (PR #276) | "display A" variant: `simple-framebuffer` on the bootloader framebuffer at `0xfac00000` (1344x2992, a8r8g8b8); Nura shows `login:` on it (Milestone 2); command-mode DSI panel, frames at ~60 Hz after `gs_decon.stage=1` unmasks the frame trigger. No GPU/acceleration, no real modesetting (no `km4` panel driver in the tree), no backlight device (brightness as left by the bootloader), no screen off/on. Milestone 1 tree: no output. Variant B (`gs_decon.stage=2 gs_decon.fbdev=1`, KMS flip-only) built, untested |
| Buttons (power/vol) | — | **partial** | reported (PR #276) | Nura: logind logs "Power key pressed short", but nothing powers off or reboots. From Linux, Power+Vol− does **not** reach fastboot; we got there with a button-forced reboot and then holding Vol− (exact combination not recorded). From the bootloader/stock, Power+Vol− reaches fastboot |
| Touchscreen | Synaptics (`syna_touch`) | **no input** | disabled upstream (PR #276) | cannot type at Nura's on-screen login; access only over SSH or the initramfs debug shell |
| GPU | Mali-G715 | untested | disabled upstream (PR #276) | |
| USB Type-C | — | untested | disabled upstream (PR #276) | |
| Charging | MAX77779 family | **not supported** | unknown | no `/sys/class/power_supply` under Nura |
| Battery / fuel gauge | MAX77779 family | **not supported** | unknown | no `/sys/class/power_supply` under Nura |
| CPU frequency | — | **works** | unknown | cpufreq (schedutil) under Nura; only `clk-acpm` and `gs101_acpm_tmu` load by modalias |
| WiFi | BCM4390 (`bcmdhd4390`) | untested | disabled upstream (PR #276) | |
| Bluetooth | unverified | untested | unknown | |
| Audio (amps/haptics) | cs35l41 / cs40l26 | untested | unknown | AoC involved (unverified how) |
| Sensors | unverified | untested | unknown | |
| Modem / calls / SMS / data | unverified | untested | unknown | |
| Cameras | unverified | untested | unknown | |
| NFC | unverified | untested | unknown | |
| Fingerprint | unverified | untested | unknown | |
| pKVM / virtualization | active on stock | untested | unknown | |

## Panel note / Nota sobre el panel

Earlier versions of this file listed the panel as "BOE NT37290", from the
module `panel_boe_nt37290` seen loaded on the previous stock build (Android 16
Beta); a third-party bring-up names it `google,gs-km4` in Google's device
tree. **Settled on 2026-11-24 (Milestone 1):** the cmdline that the bootloader
adds on our unit contains `exynos_drm.panel_name=google-km4.…`, so the
bootloader identifies this unit's panel as `google-km4`. `panel_boe_nt37290`
was the module Android loaded.

Versiones anteriores decían "BOE NT37290", por el módulo `panel_boe_nt37290`
cargado en el build stock anterior (Android 16 Beta); un bring-up de terceros
lo nombra `google,gs-km4` en el device tree de Google. **Resuelto el
2026-11-24 (hito 1):** la cmdline que añade el bootloader en nuestra unidad
contiene `exynos_drm.panel_name=google-km4.…`, así que el bootloader identifica
el panel de esta unidad como `google-km4`. `panel_boe_nt37290` era el módulo
que cargaba Android.
